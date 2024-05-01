# Packaging Directory

When you run "bundle exec rbwasm build" from the top-level directory it picks up
a ton of files, totalling (as I write this) a 1.9GB build instead of a 50MB build.
By running from a subdirectory we can get just the intended package files.

