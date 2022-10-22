# Invoice date parser

(EN)
A shell (bash) script parsing dates from PDF invoices. The default configuration contains regex patterns for English and Polish invoices.
I've tried to configure the script according to information from Polish accountant. In order to configure it for your needs, see the 'Configuration' section.

(PL)
Skrypt powłoki bash parsujący daty z faktur w PDF. Domyślna konfiguracja zawiera wzorce regex dla faktur w językach angielskim i polskim.
Starałem się skonfigurować skrypt zgodnie z informacjami z mojej (polskiej) księgowości. W razie potrzeby konfiguracji, przejdź do sekcji 'Configuration'.


## Motivation

Invoices often include multiple separate dates, such as 'invoice date', 'order date', 'payment deadline' etc. I needed a script that would automatically parse a correct date from a given invoice, so another script can move the invoice to a correct directory (i.e. with all invoices from the same month), or do any other task. I couldn't find such script, so I've decided to create one by myself.


## Issues with invoices parsing

There are a couple of problems with parsing data from PDF invoices:
- the invoices are formatted in various different ways. The actual date can be next to its name/title, or above/below the name/title. Sometimes a single line in PDF invoice contains multiple date-name pairs.
- the dates can be in multiple different formats
- the invoice can contain multiple different dates with different names/titles. Not all of them might be important.
- a different date name/title can be relevant in different case. I.e. for purchase invoice, the important dates are 'invoice date', 'issue date' etc., but for sales invoice the earliest date from a given subset is important.
- in my case the additional difficulty comes with the fact that I'm not from an English-speaking country and the invoices I deal with are in Polish or English.


## Dependencies

I wanted the script to be easily usable on most Unix/Linux machines. Therefore it uses mostly a standard set of shell tools:
- bash
- pdfgrep
- grep
- sed
- awk
- GNU date

The pdfgrep can usually be installed using apt-get, homebrew or from https://pdfgrep.org.
The GNU date is usually preinstalled with Linux. In case of MacOS it needs to be installed as a part of `coreutils`.


## Configuration

On the top of the script there are a couple of configuration options:
- VERBOSE - set to 1 to increase the amount of data printed (i.e. all matched dates)
- REGEX_NAME_ON_INVOICE - regex name on the invoice used to differentiate the purchase (buy) invoice and sales (sell) invoice
- REGEX_SELLER_FORMATS - list of regex used to find information about seller on a parsed invoice
- DATE_CMD - the GNU date command. In most cases on Linux it should be set to `date`, and on MacOS with `coreutils` it should be set to `gdate`
- SELL_INVOICE_DATE_SELECTION and BUY_INVOICE_DATE_SELECTION - type of date to be selected in case of purchase (buy) and sales (sell) invoice:
   - BEGIN   - the first matched date (according to REGEX_NAME_PRIORITY_FORMATS order)
   - END     - the last matched date (according to REGEX_NAME_PRIORITY_FORMATS order)
   - SOONEST - the soonest date matched (the fist one in the calendar order)
   - LATEST  - the latest date matched (the last one in the calendar order)
- REGEX_DATE_FORMATS - list of regex dates formats
- REGEX_NAME_PRIORITY_FORMATS - list of regex date names/titles. In case of this list, the order of regex can determine the final date output (see BUY/SELL_INVOICE_DATE_SELECTION values: BEGIN and END)
- REGEX_NAME_FALLBACK_PRIORITY_FORMATS - list of regex date names/titles checked if none of the regex on REGEX_NAME_PRIORITY_FORMATS list was matched. This list should contain more general formats, such as 'date'


## Usage

In order to parse an invoice, simply execute the script and pass the path to the invoice as an argument:
```
./parser.sh path/to/invoice.pdf
```
