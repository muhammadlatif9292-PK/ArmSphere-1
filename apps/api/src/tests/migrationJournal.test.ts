import { describe, it, expect } from "vitest";
import { readFileSync, readdirSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";

/**
 * Recurrence guardrail for the 0016/0017 orphan-migration defect:
 * a migration SQL file must always have a matching Drizzle journal entry,
 * otherwise `db:migrate` silently skips it on fresh environments.
 */
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.resolve(__dirname, "../../migrations");

describe("Drizzle migration journal consistency", () => {
  const journal = JSON.parse(
    readFileSync(path.join(migrationsDir, "meta", "_journal.json"), "utf8")
  );
  const sqlFiles = readdirSync(migrationsDir)
    .filter((f) => f.endsWith(".sql"))
    .sort();
  const tags = journal.entries.map((e: { tag: string }) => e.tag);
  const fileStems = sqlFiles.map((f) => f.replace(/\.sql$/, ""));

  it("every migration SQL file has a tracked journal entry (no orphans)", () => {
    const orphans = fileStems.filter((stem) => !tags.includes(stem));
    expect(
      orphans,
      `Orphaned migration(s) without a _journal.json entry: ${orphans.join(", ") || "none"}. ` +
        "A migration file without a journal entry is silently skipped by db:migrate on fresh environments."
    ).toEqual([]);
  });

  it("every journal entry references an existing migration SQL file", () => {
    const missing = tags.filter((tag: string) => !fileStems.includes(tag));
    expect(
      missing,
      `Journal entries referencing missing SQL files: ${missing.join(", ") || "none"}`
    ).toEqual([]);
  });

  it("journal idx values are sequential and 'when' timestamps are increasing", () => {
    const idxs = journal.entries.map((e: { idx: number }) => e.idx);
    expect(idxs).toEqual(idxs.map((_, i) => i));

    const whens = journal.entries.map((e: { when: number }) => e.when);
    const sorted = [...whens].sort((a, b) => a - b);
    expect(whens).toEqual(sorted);
  });
});
