# lib/rubocop/cop/vocabulary

Cops policing the words the code uses. Scoped to `app/**/*.rb`, `db/**/*.rb` and
`lib/**/*.rb`; `test/` is exempt, because a fixture naming the term it tests the ban
on is not a breach of the ban. The law is
[`plain-words-in-code`](../../../../docs/constitution.md), and its reasoning is
[`plain-words-in-code.md`](../../../../docs/decisions/plain-words-in-code.md).

## True of every file here

**The list is configuration, the matching is code.** A term belongs in `.rubocop.yml`
and never in a constant here. Deciding *what* is banned is a judgement; deciding
whether a name contains it is not, and only the second half belongs in Ruby.

**A name is split the way a reader reads it — on separators *and* on case humps.**
`\bterm\b` is the wrong tool: it never matches `term_id`, `club_term` or `TermCount`,
so a ban written that way lets the compound forms through, which is how a ratchet
accumulates the debt it exists to stop. Matching is case-insensitive, and it does not
inflect: every plural is its own entry, because a list that inflects is a list nobody
can read off the page.

**The whole source is scanned, comments and strings included.** A banned noun in a
comment or a user-facing string is the same defect as one in a class name — the law
binds identifiers, comments and documents alike.

**A file with no AST still has something to say.** Never gate on
`processed_source.blank?`: it is true for a file holding only comments, which is
exactly a file this cop must still read.
