#!/usr/bin/jq -rf

# Takes a combined JSON object (sona Linku JSON + augment*.json)
# as input, reshapes it, and filters it according to dictionary
# inclusion criteria.

{
    words:
        (.words
            # Reshape words to be smaller and more standard.
            | map_values(
                {
                    word,
                    pos,

                    # Remaining attributes are used for filtering, or flags
                    definition: (.translations.en.definitions // ""),

                    # Usage percentage from the latest survey is always used.
                    usage: (.usage | to_entries | sort_by(.key) | reverse[0].value // null),

                    book: (if .book == "none" then null else .book end),
                    commentary: .commentary
                }
            )
            # Exclude words matching certain criteria before processing further.
            | map_values(
                # select all...
                select(
                    (
                        # - words documented as typos;
                        (.translations.en.definitions // "" | startswith("[typo "))

                        # - words documented as reserved words
                        or (.translations.en.definitions // "" | test("\\bword reserved\\b"))

                        # - words deprecated by their creators
                        or (.translations.en.commentary // "" | test("\\bdeprecated\\b"))

                        # - words without a book *and* a usage percentage
                        #   of less than 1/3 of speakers, or no percentage
                        or (
                            (.book == null)
                                and (
                                    (.usage == null)
                                        or ((.usage // 0) < (1/3)*100)
                                )
                        )
                    )
                    | not # and then invert the selection
                )
                    | del(.commentary)
            )
        )
    , names: (
        .places
        + .languages
        + .transliterations
        + .names
    )
}
