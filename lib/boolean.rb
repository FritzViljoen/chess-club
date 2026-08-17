# frozen_string_literal: true

# Ruby has no boolean class — `true` is a TrueClass and `false` is a FalseClass —
# so a flag argument could not name its type without a union, and `TypedArguments` takes
# one type per argument.
#
# This marker closes the gap: `typed(provisional, Boolean)` holds for exactly
# `true` and `false`. Nothing else, ever — no truthiness, no `"1"`, no `0`.
# Turning what arrives over HTTP into one of those two values is the seam's job
# (`TypedParams#boolean_param`).
module Boolean
end

TrueClass.include(Boolean)
FalseClass.include(Boolean)
