#!/usr/bin/jq -rf

# Takes a combined JSON object (jasima Linku JSON + augment*.json)
# as input, reshapes it, and filters it according to dictionary
# inclusion criteria.

{
    words:
        (.data
            # Reshape data to be smaller and more standard.
            | map_values(
                {
                    word,
                    pos,

                    # Remaining attributes are used for filtering, or flags
                    etymology,
                    def: (.def.en),

                    # First recognition percentage is used as it's always the
                    # latest survey taken.
                    recognition: (first(.recognition[]? | tonumber) // null),

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
                        ( .etymology // "" | startswith("typo ") )

                        # - words documented as reserved words
                        or ( .def // "" | test("\\bword reserved\\b") )

                        # - words deprecated by their creators
                        or ( .commentary // "" | test("\\bdeprecated\\b") )

                        # - words without a book *and* a recognition percentage
                        #   of less than 1/3 of speakers, or no percentage
                        or (
                            (.book == null)
                                and (
                                    (.recognition == null)
                                        or ((.recognition // 0) < (1/3)*100)
                                )
                        )
                    )
                    | not # and then invert the selection
                )
            )
        )
    , names: (
        .places
        + .languages
        + .transliterations
        + .names
    )
}
