import crypto from "crypto";
import { b2Client } from "../config/b2.js";
import { PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { createPresignedPost } from "@aws-sdk/s3-presigned-post";
import env from "../config/env.js";
import { BadRequestError, logger } from "@armsphere/core";

export function stripExif(buffer: Buffer): Buffer {
  // Safe JPEG EXIF stripper
  if (buffer.length < 4 || buffer[0] !== 0xFF || buffer[1] !== 0xD8) {
    // If not JPEG, return as-is (PNG/WebP have different or no embedded camera/GPS EXIF payloads)
    return buffer;
  }
  
  let i = 2;
  const result: number[] = [0xFF, 0xD8];
  
  while (i < buffer.length) {
    if (buffer[i] === 0xFF) {
      if (i + 1 >= buffer.length) break;
      const marker = buffer[i + 1];
      
      // End of image
      if (marker === 0xD9) {
        result.push(0xFF, 0xD9);
        break;
      }
      
      // APP1 marker (contains EXIF, typically starting with FFE1)
      if (marker === 0xE1) {
        // Skip APP1 marker length + payload
        if (i + 3 >= buffer.length) break;
        const length = (buffer[i + 2] << 8) + buffer[i + 3];
        i += 2 + length;
        continue;
      }
      
      // Other markers - copy them
      if (i + 3 >= buffer.length) {
        result.push(buffer[i]);
        i++;
        continue;
      }
      const length = (buffer[i + 2] << 8) + buffer[i + 3];
      for (let j = 0; j < 2 + length; j++) {
        if (i + j < buffer.length) {
          result.push(buffer[i + j]);
        }
      }
      i += 2 + length;
    } else {
      result.push(buffer[i]);
      i++;
    }
  }
  
  return Buffer.from(result);
}

export function stripPngMetadata(buffer: Buffer): Buffer {
  // Safe PNG metadata stripper for tEXt, zTXt, iTXt, and eXIf chunks
  if (buffer.length < 8) {
    return buffer;
  }
  
  const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (let i = 0; i < 8; i++) {
    if (buffer[i] !== pngSignature[i]) {
      return buffer;
    }
  }

  const result: number[] = [...pngSignature];
  let i = 8;
  
  while (i < buffer.length) {
    if (i + 8 > buffer.length) {
      break;
    }
    
    const length = buffer.readUInt32BE(i);
    const chunkType = buffer.toString("ascii", i + 4, i + 8);

    if (i + 12 + length > buffer.length) {
      break;
    }

    const typeLower = chunkType.toLowerCase();
    // Strip metadata chunks: tEXt, zTXt, iTXt, eXIf (and case-insensitive exif for safety)
    if (
      chunkType === "tEXt" ||
      chunkType === "zTXt" ||
      chunkType === "iTXt" ||
      chunkType === "eXIf" ||
      typeLower === "exif"
    ) {
      // Skip this chunk: 4 bytes length + 4 bytes type + length bytes data + 4 bytes CRC
      i += 12 + length;
      continue;
    }

    // Copy the chunk
    for (let j = 0; j < 12 + length; j++) {
      result.push(buffer[i + j]);
    }
    i += 12 + length;
  }

  return Buffer.from(result);
}

export interface StorageProvider {
  putObject(
    bucketName: string,
    fileKey: string,
    buffer: Buffer,
    contentType: string,
    sha256Hash: string
  ): Promise<void>;

  generatePresignedUploadUrl(
    bucketName: string,
    fileKey: string,
    expirySeconds: number
  ): Promise<string>;

  generatePresignedDownloadUrl(
    bucketName: string,
    fileKey: string,
    expirySeconds: number
  ): Promise<string>;

  generatePresignedPostPolicy(
    bucketName: string,
    fileKey: string,
    expirySeconds: number,
    maxSizeBytes: number,
    mimeType: string
  ): Promise<{ postURL: string; formData: Record<string, string> }>;
}

export class B2Provider implements StorageProvider {
  async putObject(
    bucketName: string,
    fileKey: string,
    buffer: Buffer,
    contentType: string,
    sha256Hash: string
  ): Promise<void> {
    if (env.NODE_ENV === "test" || process.env.VITEST === "true") {
      return;
    }
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: fileKey,
      Body: buffer,
      ContentType: contentType,
      Metadata: {
        sha256: sha256Hash,
      },
    });
    await b2Client.send(command);
  }

  async generatePresignedUploadUrl(
    bucketName: string,
    fileKey: string,
    expirySeconds: number
  ): Promise<string> {
    if (env.NODE_ENV === "test" || process.env.VITEST === "true") {
      return "http://localhost:9000/mock-presigned-put-url";
    }
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: fileKey,
    });
    return await getSignedUrl(b2Client, command, { expiresIn: expirySeconds });
  }

  async generatePresignedDownloadUrl(
    bucketName: string,
    fileKey: string,
    expirySeconds: number
  ): Promise<string> {
    if (env.NODE_ENV === "test" || process.env.VITEST === "true") {
      return `http://localhost:9000/mock-download-url/${bucketName}/${fileKey}`;
    }
    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: fileKey,
    });
    return await getSignedUrl(b2Client, command, { expiresIn: expirySeconds });
  }

  async generatePresignedPostPolicy(
    bucketName: string,
    fileKey: string,
    expirySeconds: number,
    maxSizeBytes: number,
    mimeType: string
  ): Promise<{ postURL: string; formData: Record<string, string> }> {
    if (env.NODE_ENV === "test" || process.env.VITEST === "true") {
      return {
        postURL: "http://localhost:9000/mock-presigned-post-url",
        formData: {
          key: fileKey,
          bucket: bucketName,
          "Content-Type": mimeType,
          policy: "mock-b2-policy-base64",
          "x-amz-signature": "mock-signature",
          conditions: JSON.stringify([
            ["content-length-range", 0, maxSizeBytes],
            ["eq", "$Content-Type", mimeType],
          ]),
        },
      };
    }

    const { url, fields } = await createPresignedPost(b2Client, {
      Bucket: bucketName,
      Key: fileKey,
      Conditions: [
        ["content-length-range", 0, maxSizeBytes],
        ["eq", "$Content-Type", mimeType],
      ],
      Expires: expirySeconds,
      Fields: {
        "Content-Type": mimeType,
      },
    });

    return {
      postURL: url,
      formData: fields,
    };
  }
}

export class StorageService {
  /**
   * Allowed file types and sizing rules (Strictly AVATAR and DOCUMENT only. Video is URL-reference only).
   */
  private static readonly RULES: Record<"AVATAR" | "DOCUMENT", { maxSize: number; allowedMime: string[]; bucket: string }> = {
    AVATAR: {
      maxSize: 2 * 1024 * 1024, // 2MB
      allowedMime: ["image/jpeg", "image/jpg", "image/png"],
      get bucket() {
        return env.B2_BUCKET_ATHLETE_AVATARS;
      },
    },
    DOCUMENT: {
      maxSize: 10 * 1024 * 1024, // 10MB
      allowedMime: ["image/jpeg", "image/jpg", "image/png", "application/pdf"],
      get bucket() {
        return env.B2_BUCKET_COMPLIANCE_DOCS;
      },
    },
  };

  /**
   * Resolves active storage provider based on environment setting
   */
  private static getProvider(): StorageProvider {
    return new B2Provider();
  }

  /**
   * Process direct file uploads: Strips JPEG EXIF/PNG metadata, computes SHA-256 integrity hash, validates MIME and size limits
   */
  static async processAndUploadDirect(
    fileType: "AVATAR" | "DOCUMENT",
    fileName: string,
    mimeType: string,
    rawBuffer: Buffer
  ) {
    if (mimeType.toLowerCase().startsWith("video/")) {
      throw new BadRequestError("ArmSphere does not host video files. Video must be provided via URL reference.");
    }

    const rules = this.RULES[fileType];
    if (!rules) {
      throw new BadRequestError("Unsupported upload categorization.");
    }

    // 1. Size Validation
    if (rawBuffer.length > rules.maxSize) {
      throw new BadRequestError(`File exceeds maximum size threshold of ${rules.maxSize / (1024 * 1024)}MB.`);
    }

    // 2. MIME Type Verification
    if (!rules.allowedMime.includes(mimeType.toLowerCase())) {
      throw new BadRequestError(`MIME type '${mimeType}' is restricted. Allowed options: ${rules.allowedMime.join(", ")}`);
    }

    // 3. EXIF Stripping / Image Sanitization
    let processedBuffer = rawBuffer;
    const lowerMime = mimeType.toLowerCase();
    if (lowerMime === "image/jpeg" || lowerMime === "image/jpg") {
      logger.info({ fileName }, "Sanitizing image and stripping GPS/Camera EXIF metadata");
      processedBuffer = stripExif(rawBuffer);
    } else if (lowerMime === "image/png") {
      logger.info({ fileName }, "Sanitizing PNG image and stripping embedded metadata chunks (tEXt/iTXt/zTXt/eXIf)");
      processedBuffer = stripPngMetadata(rawBuffer);
    }

    // 4. Compute SHA-256 Integrity Hash
    const sha256Hash = crypto.createHash("sha256").update(processedBuffer).digest("hex");

    // 5. Build unique path-safe file key
    const extension = fileName.split(".").pop() || "bin";
    const fileKey = `${fileType.toLowerCase()}s/${crypto.randomUUID()}.${extension}`;

    // 6. Upload directly via B2 provider
    const provider = this.getProvider();
    await provider.putObject(rules.bucket, fileKey, processedBuffer, mimeType, sha256Hash);

    logger.info({ fileKey, bucket: rules.bucket, sha256Hash, provider: env.STORAGE_PROVIDER }, "Uploaded sanitized file successfully");

    return {
      fileKey,
      bucketName: rules.bucket,
      sha256Hash,
      mimeType,
      size: processedBuffer.length,
    };
  }

  /**
   * Generates secure presigned PUT URL for client-side uploads with size & MIME metadata locks
   */
  static async generatePresignedUploadUrl(
    fileType: "AVATAR" | "DOCUMENT",
    fileName: string,
    mimeType: string,
    size: number
  ) {
    if (mimeType.toLowerCase().startsWith("video/")) {
      throw new BadRequestError("ArmSphere does not host video files. Video must be provided via URL reference.");
    }

    const rules = this.RULES[fileType];
    if (!rules) {
      throw new BadRequestError("Unsupported upload categorization.");
    }

    if (size > rules.maxSize) {
      throw new BadRequestError(`File exceeds maximum size threshold of ${rules.maxSize / (1024 * 1024)}MB.`);
    }

    if (!rules.allowedMime.includes(mimeType.toLowerCase())) {
      throw new BadRequestError(`MIME type '${mimeType}' is restricted.`);
    }

    const extension = fileName.split(".").pop() || "bin";
    const fileKey = `${fileType.toLowerCase()}s/${crypto.randomUUID()}.${extension}`;

    const provider = this.getProvider();

    const policyResult = await provider.generatePresignedPostPolicy(
      rules.bucket,
      fileKey,
      600,
      rules.maxSize,
      mimeType
    );

    return {
      postURL: policyResult.postURL,
      formData: policyResult.formData,
      fileKey,
      bucketName: rules.bucket,
      expiryInSeconds: 600,
    };
  }

  /**
   * Generates temporary presigned GET URL for authenticated viewing of private compliance assets
   */
  static async generatePresignedDownloadUrl(bucketName: string, fileKey: string) {
    const provider = this.getProvider();
    const downloadUrl = await provider.generatePresignedDownloadUrl(bucketName, fileKey, 3600); // 1 hour validity
    return downloadUrl;
  }
}

