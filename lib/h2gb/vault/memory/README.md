memory/ is an abstraction of a binary or whatever that gets loaded into memory.

The "public" class is [memory.rb](memory.rb), and the functions are documented
there. This is an overview of the full abstraction.

The memory class is initialized with a contiguous array of bytes, `raw`. Those
bytes are indexed from zero, so if you're dealing with something that requires
relocations, you've gotta do those at another layer. The memory abstraction is
defined in [memory_block.rb](memory_block.rb).

Overlaid on those bytes are a series of `entries`. An entry is defined in
[memory_entry.rb](memory_entry.rb), but the implementation details aren't
important.

Basically, each entry in memory has a few values:
* `address`: The starting address of the entry
* `length`: The length (in bytes) of the entry
* `data`: Any structured or unstructured data you want - this is where most of
  the code goes
* `refs`: The other addresses that this references (as absolute values, at this
  point; might add the option for relative offsets if it winds up being necessary

Entries can't overlap with other entries. If an overlapping entry is created,
any entries it would overlap are deleted first.

The only other thing to know is transactions - all insert/delete/update/etc
has to be wrapped in a transaction() call. This is to help assign revision
numbers, do mutex locking, etc.

If you use this library, you get a few "freebies"! Specifically:
* Automatic undo and redo support
** All Actions (insert/delete/edit/etc) are tracked in an undo buffer, and can
   be reversed using a typical undo/redo scheme.
** The code for the undo support is in
   [memory_transaction.rb](memory_transaction.rb). The implementation is fairly
   generic, but I'd be curious to hear others' takes on it; I've never written
   or researched the right way to do undo/redo before!
* Automatic cross-references!
** Cross references are updated each time a reference is added and removed
* Versioning support!
** Every entry and change is versioned, and the get() function has support for
   getting only changes since a particular revision
** For a bigger codebase, this could be helpful to avoid re-reading an entire
   binary every time
** Right now the support isn't SUPER efficient - it's `O(n)`, which might be
   an issue for bigger files - but it can be improved if needed
* Easy save/load support!
** Can be persisted with typical ruby functions, like `YAML::dump()` and
   `YAML::load()`
