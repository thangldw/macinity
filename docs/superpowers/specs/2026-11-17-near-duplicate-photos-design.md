# Near-duplicate photo review — design (short)

Approved by the user in conversation on 2026-11-17.

## Intent and why
Find photos that are the same picture in different versions (resized, recompressed, converted,
stored in two folders) and photos that are very similar (>= 90% estimated), and give a review
list showing what to keep and what to delete before anything is moved to Trash.

## Goals
- Scan a whole chosen root, not only same-folder / 10-second bursts.
- Review list per group: per-photo Keep/Delete state pre-filled from the suggestion with a stated
  reason, folder, resolution, size, capture date, sharpness; side-by-side compare; summary bar
  (keep N, delete M, bytes freed); similarity slider 80-100% (default 90%); folder filter.
- Always keep at least one photo per group.
- Deletion = move to Trash with the existing history/recovery journal. Nothing automatic.

## Non-goals / anti-goals
- No permanent delete, no automatic cleanup, no cloud upload, no Photos-library scanning
  (packages are skipped by the existing scanner policy).
- The similarity number is an estimate (1 - Vision distance), never presented as a probability.
- Anti-goal: a scan that cannot finish on a large library or deletes without review.

## Approaches considered
A. Loosen the existing scanner (no folder/time gate): simplest, but pairwise Vision comparison is
   O(n^2), no cache, misses resized/recompressed copies.
B. (chosen) Two stages: 64-bit dHash candidates found via an index (not all pairs), Vision
   feature-print distance confirms, persistent cache keyed by path+size+mtime.
C. Vision only with cache and LSH: slow first scan, cannot separate "same image" from "similar scene".
The existing burst mode (same folder, 10 s) is kept as a separate mode.

## Design
- `PhotoFingerprint` (dHash 9x8 grayscale from an ImageIO thumbnail), Hamming distance.
- `PhotoHashIndex`: multi-index hashing (64 bits split in 8 bytes; pigeonhole bucket lookup for
  Hamming <= 7) to produce candidate pairs without all-pairs comparison.
- Confirmation: Vision `VNFeaturePrintObservation` distance <= 1 - threshold; union-find groups.
- `PhotoFingerprintCache`: JSON in Application Support, bounded entries, invalidated by size/mtime;
  unreadable cache is ignored, never overwritten blindly.
- Keep suggestion: highest pixel count, then sharpness, then bytes (existing rule) plus a reason.
- Threshold is a view-model value; regrouping on slider change reuses confirmed pair distances.

## Left to the builder
Exact multi-index tuning, thumbnail size, UI layout details, cache size cap, localization wording.
