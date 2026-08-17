# One person's place in a calculated order: who, and where.
#
# Not a record. CalculateStandings answers with these and WriteStandingsCache
# persists them, so the pair travels between the two named rather than as a tuple
# whose halves have to be remembered by position.
Standing = Data.define(:person_id, :position)
