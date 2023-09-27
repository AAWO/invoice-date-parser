#!/bin/bash

# Description  : A PDF invoice dates parser
# Argument     : Path to a PDF invoice file
# Author       : Andrzej Wojciechowski (AAWO)
# License      : GNU General Public License

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

VERBOSE=0

# Sell/buy invoice detection
REGEX_NAME_ON_INVOICE="Super important company inc."

# Sell/buy invoice detection
REGEX_SELLER_FORMATS=(
   'sprzedawca'
   'seller'
)

# pdfgrep command path
# path can be found using 'which pdfgrep'
PDFGREP_CMD='/opt/homebrew/bin/pdfgrep'

# GNU date command path
# in Linux it's simply 'date'
# in MacOS the GNU date can be accessed as 'gdate'
# path can be found using 'which gdate'
DATE_CMD='/opt/homebrew/bin/gdate'

# The selection mechanism for sell/buy invoice date selection
# Accepted values:
#     - BEGIN   - the first matched date (according to REGEX_NAME_PRIORITY_FORMATS order)
#     - END     - the last matched date (according to REGEX_NAME_PRIORITY_FORMATS order)
#     - SOONEST - the soonest date matched (the fist one in the calendar order)
#     - LATEST  - the latest date matched (the last one in the calendar order)
SELL_INVOICE_DATE_SELECTION='SOONEST'
BUY_INVOICE_DATE_SELECTION='BEGIN'

# Regex for dates detection
REGEX_DATE_FORMATS=(
   '[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}'
   '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}'
   '[0-9]{4}(-|\xAD)[0-9]{1,2}(-|\xAD)[0-9]{1,2}'
   '[0-9]{1,2}(-|\xAD)[0-9]{1,2}(-|\xAD)[0-9]{4}'
   '[0-9]{4}\/[0-9]{1,2}\/[0-9]{1,2}'
   '[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}'
   '[0-9]{1,2}-(jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|jun(e)?|jul(y)?|aug(ust)?|sep(tember)?|oct(ober)?|(nov|dec)(ember)?)-([0-9]{2}|\d{4})'
   '[0-9]{1,2}\s(jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|jun(e)?|jul(y)?|aug(ust)?|sep(tember)?|oct(ober)?|(nov|dec)(ember)?)\s([0-9]{2}|\d{4})'
   '(jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|jun(e)?|jul(y)?|aug(ust)?|sep(tember)?|oct(ober)?|(nov|dec)(ember)?)\s[0-9]{1,2},\s([0-9]{2}|\d{4})'
   '[0-9]{1,2}-(sty(czeń|czen|cznia)?|lut(y|ego)?|mar(zec|ca)?|kwi(ecień|ecien|etnia)?|maj(a)?|cze(rwiec|rwca)?|lip(iec|ca)?|sie(rpień|rpien|rpnia)?|wrz(esień|esien|eśnia|esnia)?|pa(ź|z)(dziernik|dziernika)?|lis(topad|topada)?|gru(dzień|dzien|dnia)?)-([0-9]{2}|\d{4})'
   '[0-9]{1,2}\s(sty(czeń|czen|cznia)?|lut(y|ego)?|mar(zec|ca)?|kwi(ecień|ecien|etnia)?|maj(a)?|cze(rwiec|rwca)?|lip(iec|ca)?|sie(rpień|rpien|rpnia)?|wrz(esień|esien|eśnia|esnia)?|pa(ź|z)(dziernik|dziernika)?|lis(topad|topada)?|gru(dzień|dzien|dnia)?)\s([0-9]{2}|\d{4})'
)

# Regex for date name detection - standard names
# in decreasing priority order
REGEX_NAME_PRIORITY_FORMATS=(
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data wystawienia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data wystawienia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data [a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ[:space:]]+wystawienia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?wystawiono dnia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data dokumentu[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data faktury[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data faktury/data dostawy[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?faktura z dnia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?invoice date[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data dostawy lub świadczenia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data dostawy lub swiadczenia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data sprzedaży[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data sprzedazy[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?data wykonania[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?order created[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]?\s*'
)

# Regex for date name detection - fallback (most general) names
# in decreasing priority order
REGEX_NAME_FALLBACK_PRIORITY_FORMATS=(
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]date[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ], dnia[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]data[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
   '[a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ], [^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]'
)

MONTH_NAMES=(
   'jan'
   'feb'
   'mar'
   'apr'
   'may'
   'jun'
   'jul'
   'aug'
   'sep'
   'oct'
   'nov'
   'dec'
)

#################################################

function count_unique() {
   local LC_ALL=C

   if [ "$#" -eq 0 ] ; then 
      echo 0
   else
      echo "$(printf "%s\000" "$@" |
               sort --zero-terminated --unique |
               grep --null-data --count .)"
   fi
}

function format_date() {
   if [[ -z "$1" ]]; then
      return
   fi
   local DATE_TMP=`sed -E 's/(sty(czeń|cznia)?)/jan/g' <<< $1 \
                 | sed -E 's/(lut(y|ego)?)/feb/g' \
                 | sed -E 's/(mar(zec|ca)?)/mar/g' \
                 | sed -E 's/(kwi(ecień|etnia)?)/apr/g' \
                 | sed -E 's/(maj(a)?)/may/g' \
                 | sed -E 's/(cze(rwiec|rwca)?)/jun/g' \
                 | sed -E 's/(lip(iec|ca)?)/jul/g' \
                 | sed -E 's/(sie(rpień|rpnia)?)/aug/g' \
                 | sed -E 's/(wrz(esień|eśnia)?)/sep/g' \
                 | sed -E 's/(paź(dziernik|dziernika)?)/oct/g' \
                 | sed -E 's/(lis(topad|topada)?)/nov/g' \
                 | sed -E 's/(gru(dzień|dnia)?)/dec/g' \
                 | sed 's/[^0-9a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]/-/g'`

   local RES=`awk -F '-' -v par="${MONTH_NAMES[*]}" '{ n = split(par, a, " "); if ($2 ~ /^[0-9]+$/) { if (length($1)==4) printf("%02d-%s-%d\n", int($3), a[int($2)], int($1)); else printf("%02d-%s-%d\n", int($1), a[int($2)], int($3)); } else { if (length($1)==4) printf("%02d-%s-%d\n", int($3), tolower($2), int($1)); else printf("%02d-%s-%d\n", int($1), tolower($2), int($3)); }; exit }' <<< "$DATE_TMP"`
   echo "$RES"
}

function date2epoch() {
   echo $("$DATE_CMD" -d "$1" +%s)
}

function epoch2date() {
   echo $("$DATE_CMD" -d @"$1" +'%d-%m-%Y')
}

function parse_row() {
   # arg $1: path to parsed file
   # arg $2: regex name format

   local PDFGREP_RESULT=`$PDFGREP_CMD -i "$2" "$1"`

   if [[ ! -z "$PDFGREP_RESULT" ]]; then
      # skip if the current $REGEX_NAME_FORMAT not found using pdfgrep
      for REGEX_DATE_FORMAT in "${REGEX_DATE_FORMATS[@]}"; do
         # in some cases matched regex name format contains multiple name-date pairs
         if [[ "${2: -1}" == "?" ]]; then
            # don't add '+', if the last character in $2 (regex name format) is '?'
            # the '?+' regex operator is invalid
            local DATE_LINES=`grep -Eoi "$2$REGEX_DATE_FORMAT" <<< "$PDFGREP_RESULT"`
         else
            local DATE_LINES=`grep -Eoi "$2+$REGEX_DATE_FORMAT" <<< "$PDFGREP_RESULT"`
         fi
         if [[ ! -z "$DATE_LINES" ]]; then
            # skip if the current $REGEX_DATE_FORMAT not found
            RESULTS+=($(format_date "`grep -Eoi "$REGEX_DATE_FORMAT" <<< "$DATE_LINES"`"))
         fi
      done
   fi
}

function parse_column() {
   # arg $1: path to parsed file
   # arg $2: regex name format

   local PDFGREP_RESULT=`$PDFGREP_CMD -C 3 -i "$2" "$1"`
   
   if [[ ! -z "$PDFGREP_RESULT" ]]; then
      # skip if the current $REGEX_NAME_FORMAT not found using pdfgrep
      # get indexes of columns containing $REGEX_NAME_FORMAT
      COLUMNS_IDX=($(awk -F ' {2,}' -v PATTERN="$2" '{ for (i=1; i<=NF; ++i) { if (tolower($i) ~ PATTERN) print i } }' <<< "$PDFGREP_RESULT"))

      for COLUMN_IDX in "${COLUMNS_IDX[@]}"; do
         COLUMN=`awk -F ' {2,}' -v COL_ID="$COLUMN_IDX" '{ print $COL_ID }' <<< "$PDFGREP_RESULT"`
   
         for REGEX_DATE_FORMAT in "${REGEX_DATE_FORMATS[@]}"; do
            RESULTS+=($(format_date "`grep -Eoi "$REGEX_DATE_FORMAT" <<< "$COLUMN"`"))
         done
      done
   fi
}

#################################################

if [[ "$VERBOSE" == 1 ]]; then
   echo "Stage 1 - Sell/buy invoice detection"
fi

INVOICE_TYPE=BUY

for REGEX_SELLER_FORMAT in "${REGEX_SELLER_FORMATS[@]}"; do
   PDFGREP_RESULT=`$PDFGREP_CMD -i "[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]$REGEX_SELLER_FORMAT[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]" "$1" | sed 's/[ ][ ].*//g' | grep -oi "$REGEX_NAME_ON_INVOICE"`

   if [[ ! -z "$PDFGREP_RESULT" ]]; then
      INVOICE_TYPE=SELL
      break
   fi
done

if [[ ! -z "$PDFGREP_RESULT" ]]; then
   for REGEX_SELLER_FORMAT in "${REGEX_SELLER_FORMATS[@]}"; do
      PDFGREP_RESULT=`$PDFGREP_CMD -i "[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]$REGEX_SELLER_FORMAT[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]" "$1" | grep -oi "$REGEX_NAME_ON_INVOICE"`
   
      if [[ ! -z "$PDFGREP_RESULT" ]]; then
         INVOICE_TYPE=SELL
         break
      fi
   done
fi

if [[ -z "$PDFGREP_RESULT" ]]; then
   for REGEX_SELLER_FORMAT in "${REGEX_SELLER_FORMATS[@]}"; do
      PDFGREP_RESULT=`$PDFGREP_CMD -C 3 -i "[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]$REGEX_SELLER_FORMAT[^a-zA-ZżźćńółęąśŻŹĆĄŚĘŁÓŃ]" "$1"`

      # if space before $REGEX_SELLER_FORMAT -> remove leading spaces
      if grep -iq '[[:space:]]sprzedawca' <<< "$PDFGREP_RESULT"; then
         PDFGREP_RESULT=`sed 's/^[[:space:]]*//' <<< "$PDFGREP_RESULT"`
      fi

      if [[ -z "$PDFGREP_RESULT" ]]; then
         # skip to the next $REGEX_SELLER_FORMAT if the current
         # $REGEX_SELLER_FORMAT not found using pdfgrep
         continue
      fi

      # get indexes of columns containing $REGEX_SELLER_FORMAT
      COLUMNS_IDX=($(awk -F ' {2,}' -v PATTERN="$REGEX_SELLER_FORMAT" '{ for (i=1; i<=NF; ++i) { if (tolower($i) ~ PATTERN) print i } }' <<< "$PDFGREP_RESULT"))
      if [[ -z "$COLUMNS_IDX" ]]; then
         continue
      fi
      COLUMN=`awk -F ' {2,}' -v COL_ID="$COLUMNS_IDX" '{ print $COL_ID }' <<< "$PDFGREP_RESULT"`

      PDFGREP_RESULT=`grep -oi "$REGEX_NAME_ON_INVOICE" <<< "$COLUMN"`
      if [[ ! -z "$PDFGREP_RESULT" ]]; then
         INVOICE_TYPE=SELL
         break
      fi
   done
fi

if [[ "$VERBOSE" == 1 ]]; then
   echo "Invoice type: $INVOICE_TYPE"
fi

#################################################

if [[ "$VERBOSE" == 1 ]]; then
   echo "Stage 2 - Row parsing"
fi

for REGEX_NAME_FORMAT in "${REGEX_NAME_PRIORITY_FORMATS[@]}"; do
   parse_row "$1" "$REGEX_NAME_FORMAT"
done

if [[ -z "$RESULTS" ]]; then
   if [[ "$VERBOSE" == 1 ]]; then
      echo "Stage 3 - Column parsing"
   fi
   
   for REGEX_NAME_FORMAT in "${REGEX_NAME_PRIORITY_FORMATS[@]}"; do
      parse_column "$1" "$REGEX_NAME_FORMAT"
   done
fi

if [[ -z "$RESULTS" ]]; then
   if [[ "$VERBOSE" == 1 ]]; then
      echo "Stage 4 - Row parsing with fallback patterns"
   fi

   for REGEX_NAME_FORMAT in "${REGEX_NAME_FALLBACK_PRIORITY_FORMATS[@]}"; do
      parse_row "$1" "$REGEX_NAME_FORMAT"
   done
fi

if [[ -z "$RESULTS" ]]; then
   if [[ "$VERBOSE" == 1 ]]; then
      echo "Stage 5 - Column parsing with fallback patterns"
   fi

   for REGEX_NAME_FORMAT in "${REGEX_NAME_FALLBACK_PRIORITY_FORMATS[@]}"; do
      parse_column "$1" "$REGEX_NAME_FORMAT"
   done
fi

if [[ -z "$RESULTS" ]]; then
   echo "Couldn't match any date patterns"
   exit 1
fi

if [[ "$VERBOSE" == 1 ]]; then
   echo -e "\nFound dates:\n${RESULTS[@]}"
   echo -e "\nInvoice type: $INVOICE_TYPE"
   if [[ "$INVOICE_TYPE" = "SELL" ]]; then
      echo "Sell invoice date selection: $SELL_INVOICE_DATE_SELECTION"
   elif [[ "$INVOICE_TYPE" = "BUY" ]]; then
      echo "Buy invoice date selection: $BUY_INVOICE_DATE_SELECTION"
   fi
fi

if [ "$(count_unique "${RESULTS[@]}")" -eq 1 ] ; then
   # the first date if all matched dates are the same
   RESULT_FINAL=$(epoch2date "$(date2epoch "${RESULTS[0]}")")
else
   if [[ "$INVOICE_TYPE" = "SELL" && "$SELL_INVOICE_DATE_SELECTION" = "BEGIN" ]]; then
      RESULT_FINAL=$(epoch2date "$(date2epoch "${RESULTS[0]}")")
   elif [[ "$INVOICE_TYPE" = "BUY" && "$BUY_INVOICE_DATE_SELECTION" = "BEGIN" ]]; then
      RESULT_FINAL=$(epoch2date "$(date2epoch "${RESULTS[0]}")")
   elif [[ "$INVOICE_TYPE" = "SELL" && "$SELL_INVOICE_DATE_SELECTION" = "END" ]]; then
      RESULT_FINAL=$(epoch2date "$(date2epoch "${RESULTS[${#RESULTS[@]} - 1]}")")
   elif [[ "$INVOICE_TYPE" = "BUY" && "$BUY_INVOICE_DATE_SELECTION" = "END" ]]; then
      RESULT_FINAL=$(epoch2date "$(date2epoch "${RESULTS[${#RESULTS[@]} - 1]}")")
   else
      TMP_EPOCH=$(date2epoch "${RESULTS[0]}")
      # iterate over all dates, if matched dates are different
      for RES in "${RESULTS[@]}"; do
         RES_EPOCH=$(date2epoch "$RES")
         if [[ "$INVOICE_TYPE" = "SELL" && "$SELL_INVOICE_DATE_SELECTION" = "SOONEST" && "$RES_EPOCH" -lt "$TMP_EPOCH" ]]; then
            TMP_EPOCH=$RES_EPOCH
         elif [[ "$INVOICE_TYPE" = "BUY" && "$BUY_INVOICE_DATE_SELECTION" = "SOONEST" && "$RES_EPOCH" -lt "$TMP_EPOCH" ]]; then
            TMP_EPOCH=$RES_EPOCH
         elif [[ "$INVOICE_TYPE" = "SELL" && "$SELL_INVOICE_DATE_SELECTION" = "LATEST" && "$RES_EPOCH" -gt "$TMP_EPOCH" ]]; then
            TMP_EPOCH=$RES_EPOCH
         elif [[ "$INVOICE_TYPE" = "BUY" && "$BUY_INVOICE_DATE_SELECTION" = "LATEST" && "$RES_EPOCH" -gt "$TMP_EPOCH" ]]; then
            TMP_EPOCH=$RES_EPOCH
         fi
      done
      RESULT_FINAL=$(epoch2date "$TMP_EPOCH")
   fi
fi

if [[ "$VERBOSE" == 1 ]]; then
   echo -e "Selected date:\n$RESULT_FINAL"
else
   echo "$RESULT_FINAL"
fi
exit 0
