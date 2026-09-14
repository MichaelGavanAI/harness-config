#!/usr/bin/env node
// Registry of local-only, never-committed fixes to repo-tracked files. Each entry restores
// its file to the known-good local state if a git operation reverted it away, using exact
// string replacements (safe/no-op if already applied).
//
// `relPath` is resolved against every clone of the repo found under the machine's known
// projects roots (~/projects, ~/Projects, both work/ and personal/, any capitalization) --
// not a single hardcoded absolute path -- so this keeps working across machines/OSes and
// regardless of the exact local clone directory name (e.g. gavanmanage vs gavanmanage-staging).
import { readFileSync, writeFileSync, existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

function findRepoClones(repoNameHints) {
  const roots = [
    join(homedir(), "projects", "work"),
    join(homedir(), "projects", "personal"),
    join(homedir(), "Projects", "Work"),
    join(homedir(), "Projects", "Personal"),
  ];
  const found = [];
  for (const root of roots) {
    let entries;
    try {
      entries = readdirSync(root, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const e of entries) {
      if (!e.isDirectory()) continue;
      if (repoNameHints.some((hint) => e.name.toLowerCase().includes(hint))) {
        found.push(join(root, e.name));
      }
    }
  }
  return found;
}

const ENTRIES = [
  {
    repoNameHints: ["gavanmanage"],
    relPath: ".claude/hooks/guard-gh-pr-create.mjs",
    fingerprint: "cwd: targetDir",
    replacements: [
      [
        "const cdMatch = cmd.match(/^\\s*cd\\s+([^&;]+)/);",
        "const cdMatch = cmd.match(/^\\s*cd\\s+([^&;\\n]+)/);",
      ],
      [
        'branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], {\n        encoding: "utf8",',
        'branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], {\n        cwd: targetDir,\n        encoding: "utf8",',
      ],
      [
        '["pr", "list", "--state", "merged", "--head", branch, "--json", "number"],\n        { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },',
        '["pr", "list", "--state", "merged", "--head", branch, "--json", "number"],\n        { cwd: targetDir, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },',
      ],
    ],
  },
];

for (const entry of ENTRIES) {
  for (const repoDir of findRepoClones(entry.repoNameHints)) {
    const file = join(repoDir, entry.relPath);
    if (!existsSync(file)) continue;
    const content = readFileSync(file, "utf8");
    if (content.includes(entry.fingerprint)) continue; // already fixed

    let next = content;
    for (const [from, to] of entry.replacements) {
      next = next.split(from).join(to);
    }
    if (next !== content) {
      writeFileSync(file, next);
      console.error(`reapply-local-hook-fixes: restored local fix to ${file}`);
    }
  }
}
