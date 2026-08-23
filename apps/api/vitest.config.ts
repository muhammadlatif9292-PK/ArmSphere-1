import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  resolve: {
    alias: [
      { find: "@armsphere/types", replacement: path.resolve(__dirname, "../../packages/types/index.ts") },
      { find: "@armsphere/core", replacement: path.resolve(__dirname, "../../packages/core/index.ts") },
      { find: "@armsphere/cryptography", replacement: path.resolve(__dirname, "../../packages/cryptography/index.ts") },
      { find: "@armsphere/db-schema", replacement: path.resolve(__dirname, "../../packages/db-schema/index.ts") }
    ]
  },
  test: {
    globals: false,
    environment: "node",
    include: ["src/tests/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary"]
    },
    testTimeout: 30000
  }
});
