#!/usr/bin/jq -rf

# Takes a filtered dictionary as input, and produces a hunspell(5)
# .dic file.

# Prefix all the data with a word count, as per hunspell(5).
(.words | keys | length)+(.names | length),
(.words
    # Do the actual data processing
    | map(
        .word
        + "/kc" # Mark all words as not allowing changes in their case.
        + (
            # Forbid suggesting words that are neither recognized by
            # either >=66% of word survey respondants, nor in pu.
            if (
                (.book == "pu")
                    or (
                        (.recognition >= ((1/3)*2)*100)
                    )
                ) then
                ""
            else
                "/ns"
            end
        )
        + (
            # If the word object contains an array with the parts of speech,
            # include it. If it does not, just silently move on.
            # Parts of speech are currently not stored in Linku itself,
            # but rather comes from our augment.json, awaiting it appearing
            # in nimi Linku someday.
            if (.pos != null) then
                (.pos | " po:" + join(" po:"))
            else
                ""
            end
        )
        # + (
        #     # Add any additional hunspell flags.
        #     if (.flags != null) then
        #         (.flags | join(" "))
        #     else
        #         ""
        #     end
        # )
    )[]
)
, (.names
    | map(. + "/kc po:name")[]
)
