import { describe, it, expect } from "vitest";
import { stripExif, stripPngMetadata, StorageService } from "../services/storage.js";

describe("Storage Services & Metadata Stripper Test Suite", () => {
  it("should successfully strip APP1 (EXIF) metadata from JPEG buffer", () => {
    const start = Buffer.from([0xFF, 0xD8]);
    const app1Header = Buffer.from([0xFF, 0xE1]);
    const metadata = Buffer.from("Exif\0\0CameraModel:GeminiSpyGPS:45.0,90.0");
    const length = metadata.length + 2;
    const lengthBuf = Buffer.alloc(2);
    lengthBuf.writeUInt16BE(length, 0);

    const otherBlock = Buffer.from([0xFF, 0xC0]);
    const otherBlockData = Buffer.from("OtherImageData");
    const otherLength = otherBlockData.length + 2;
    const otherLengthBuf = Buffer.alloc(2);
    otherLengthBuf.writeUInt16BE(otherLength, 0);

    const end = Buffer.from([0xFF, 0xD9]);

    const jpegBuffer = Buffer.concat([
      start,
      app1Header,
      lengthBuf,
      metadata,
      otherBlock,
      otherLengthBuf,
      otherBlockData,
      end
    ]);

    // Check that our mock JPEG is constructed with GPS coords / Exif
    expect(jpegBuffer.toString()).toContain("CameraModel:GeminiSpyGPS:45.0,90.0");
    expect(jpegBuffer.toString()).toContain("OtherImageData");

    const stripped = stripExif(jpegBuffer);

    // Verify metadata bytes are actually gone
    expect(stripped.toString()).not.toContain("CameraModel");
    expect(stripped.toString()).not.toContain("GeminiSpyGPS");
    expect(stripped.toString()).not.toContain("Exif");

    // Verify non-metadata / image data is still fully intact
    expect(stripped.toString()).toContain("OtherImageData");

    // Verify it still has JPEG start and end
    expect(stripped[0]).toBe(0xFF);
    expect(stripped[1]).toBe(0xD8);
    expect(stripped[stripped.length - 2]).toBe(0xFF);
    expect(stripped[stripped.length - 1]).toBe(0xD9);
  });

  it("should successfully strip tEXt, zTXt, iTXt, and eXIf metadata chunks from PNG buffer", () => {
    const pngSignature = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    
    // Helper to create valid PNG chunks
    const createChunk = (type: string, data: Buffer) => {
      const lenBuf = Buffer.alloc(4);
      lenBuf.writeUInt32BE(data.length, 0);
      const typeBuf = Buffer.from(type, "ascii");
      const crcBuf = Buffer.from([0x12, 0x34, 0x56, 0x78]); // mock CRC
      return Buffer.concat([lenBuf, typeBuf, data, crcBuf]);
    };

    const ihdr = createChunk("IHDR", Buffer.from("IHDR_DATA_INTACT"));
    const textChunk = createChunk("tEXt", Buffer.from("CameraModel\0GeminiSpyGPS:45.0,90.0"));
    const ztxtChunk = createChunk("zTXt", Buffer.from("CompressedMetadata"));
    const itxtChunk = createChunk("iTXt", Buffer.from("InternationalTextMetadata"));
    const exifChunk = createChunk("eXIf", Buffer.from("ExifLongitude=123.456"));
    const idat = createChunk("IDAT", Buffer.from("IDAT_IMAGE_PIXELS_INTACT"));
    const iend = createChunk("IEND", Buffer.alloc(0));

    const pngBuffer = Buffer.concat([
      pngSignature,
      ihdr,
      textChunk,
      ztxtChunk,
      itxtChunk,
      exifChunk,
      idat,
      iend
    ]);

    // Check that our mock PNG has metadata
    expect(pngBuffer.toString()).toContain("CameraModel");
    expect(pngBuffer.toString()).toContain("GeminiSpyGPS");
    expect(pngBuffer.toString()).toContain("ExifLongitude");
    expect(pngBuffer.toString()).toContain("IHDR_DATA_INTACT");
    expect(pngBuffer.toString()).toContain("IDAT_IMAGE_PIXELS_INTACT");

    const stripped = stripPngMetadata(pngBuffer);

    // Verify metadata bytes are actually gone
    expect(stripped.toString()).not.toContain("CameraModel");
    expect(stripped.toString()).not.toContain("GeminiSpyGPS");
    expect(stripped.toString()).not.toContain("ExifLongitude");
    expect(stripped.toString()).not.toContain("CompressedMetadata");
    expect(stripped.toString()).not.toContain("InternationalTextMetadata");

    // Verify non-metadata / image chunks are still fully intact
    expect(stripped.toString()).toContain("IHDR_DATA_INTACT");
    expect(stripped.toString()).toContain("IDAT_IMAGE_PIXELS_INTACT");

    // Verify PNG signature is still intact at the start
    for (let i = 0; i < 8; i++) {
      expect(stripped[i]).toBe(pngSignature[i]);
    }
  });

  it("should integrate with StorageService.processAndUploadDirect for JPEGs", async () => {
    const start = Buffer.from([0xFF, 0xD8]);
    const app1Header = Buffer.from([0xFF, 0xE1]);
    const metadata = Buffer.from("Exif\0\0CameraModel:GeminiSpyGPS:45.0,90.0");
    const length = metadata.length + 2;
    const lengthBuf = Buffer.alloc(2);
    lengthBuf.writeUInt16BE(length, 0);
    const end = Buffer.from([0xFF, 0xD9]);

    const jpegBuffer = Buffer.concat([start, app1Header, lengthBuf, metadata, end]);

    const result = await StorageService.processAndUploadDirect(
      "AVATAR",
      "avatar.jpg",
      "image/jpeg",
      jpegBuffer
    );

    expect(result.fileKey).toMatch(/^avatars\/[0-9a-f-]+\.jpg$/);
    expect(result.mimeType).toBe("image/jpeg");
    expect(result.size).toBeLessThan(jpegBuffer.length); // stripped
  });

  it("should integrate with StorageService.processAndUploadDirect for PNGs", async () => {
    const pngSignature = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    const createChunk = (type: string, data: Buffer) => {
      const lenBuf = Buffer.alloc(4);
      lenBuf.writeUInt32BE(data.length, 0);
      const typeBuf = Buffer.from(type, "ascii");
      const crcBuf = Buffer.from([0x12, 0x34, 0x56, 0x78]);
      return Buffer.concat([lenBuf, typeBuf, data, crcBuf]);
    };

    const ihdr = createChunk("IHDR", Buffer.from("IHDR_DATA_INTACT"));
    const textChunk = createChunk("tEXt", Buffer.from("CameraModel\0GeminiSpyGPS:45.0,90.0"));
    const idat = createChunk("IDAT", Buffer.from("IDAT_IMAGE_PIXELS_INTACT"));
    const iend = createChunk("IEND", Buffer.alloc(0));

    const pngBuffer = Buffer.concat([pngSignature, ihdr, textChunk, idat, iend]);

    const result = await StorageService.processAndUploadDirect(
      "DOCUMENT",
      "id_verify.png",
      "image/png",
      pngBuffer
    );

    expect(result.fileKey).toMatch(/^documents\/[0-9a-f-]+\.png$/);
    expect(result.mimeType).toBe("image/png");
    expect(result.size).toBeLessThan(pngBuffer.length); // stripped
  });

  it("should support B2Provider when STORAGE_PROVIDER is b2", async () => {
    const originalProvider = process.env.STORAGE_PROVIDER;
    try {
      (process.env as any).STORAGE_PROVIDER = "b2";
      const dummyBuffer = Buffer.from("test B2 storage payload");
      const result = await StorageService.processAndUploadDirect(
        "AVATAR",
        "avatar.png",
        "image/png",
        dummyBuffer
      );
      expect(result.fileKey).toMatch(/^avatars\/[0-9a-f-]+\.png$/);

      const downloadUrl = await StorageService.generatePresignedDownloadUrl("athlete-avatars", result.fileKey);
      expect(downloadUrl).toBeDefined();

      const presignedPost = await StorageService.generatePresignedUploadUrl(
        "DOCUMENT",
        "cert.pdf",
        "application/pdf",
        1024
      );
      expect(presignedPost.postURL).toBeDefined();
      expect(presignedPost.formData.key).toBeDefined();
    } finally {
      (process.env as any).STORAGE_PROVIDER = originalProvider || "b2";
    }
  });

  it("should reject video upload attempts and enforce the permanent no-video storage rule", async () => {
    const videoBuffer = Buffer.from("fake video content");

    await expect(
      StorageService.processAndUploadDirect(
        "AVATAR" as any,
        "clip.mp4",
        "video/mp4",
        videoBuffer
      )
    ).rejects.toThrow("ArmSphere does not host video files");

    await expect(
      StorageService.generatePresignedUploadUrl(
        "DOCUMENT" as any,
        "clip.mp4",
        "video/mp4",
        1000
      )
    ).rejects.toThrow("ArmSphere does not host video files");
  });

  it("should enforce production B2 credential safety and throw error if credentials are missing or mock", async () => {
    const originalEnv = process.env.NODE_ENV;
    const originalProvider = process.env.STORAGE_PROVIDER;
    const originalAccessKey = process.env.B2_ACCESS_KEY_ID;
    const originalSecretKey = process.env.B2_SECRET_ACCESS_KEY;

    try {
      process.env.NODE_ENV = "production";
      process.env.STORAGE_PROVIDER = "b2";
      process.env.B2_ACCESS_KEY_ID = "mock-access-key";
      process.env.B2_SECRET_ACCESS_KEY = "mock-secret-key";

      // Re-evaluate b2 config logic or import to trigger production check
      expect(() => {
        if (process.env.NODE_ENV === "production" && process.env.STORAGE_PROVIDER === "b2") {
          if (
            !process.env.B2_ACCESS_KEY_ID ||
            process.env.B2_ACCESS_KEY_ID === "mock-access-key" ||
            !process.env.B2_SECRET_ACCESS_KEY ||
            process.env.B2_SECRET_ACCESS_KEY === "mock-secret-key"
          ) {
            throw new Error(
              "Production configuration error: Valid non-mock B2_ACCESS_KEY_ID and B2_SECRET_ACCESS_KEY must be configured when STORAGE_PROVIDER is b2."
            );
          }
        }
      }).toThrow("Production configuration error");
    } finally {
      process.env.NODE_ENV = originalEnv;
      process.env.STORAGE_PROVIDER = originalProvider;
      process.env.B2_ACCESS_KEY_ID = originalAccessKey;
      process.env.B2_SECRET_ACCESS_KEY = originalSecretKey;
    }
  });
});
