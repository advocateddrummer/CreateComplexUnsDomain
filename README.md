CreateComplexUnsDomain
======================

This Pointwise Glyph script facilitates the easy creation of an unstructured
domain that has multiple (interpretation: way more that you want to pick
manually) inner edges.


Usage
-----

Upon execution this script simply prompts the user to first select the
connectors to be used for the outer edge of the unstructured domain. However,
if the user has already selected the outer edge at runtime, this step is
skipped. Once the outer edge has been defined, the user is prompted to select
all the connectors that make up the inner edges. This script supports the
inclusion of baffles as members of the inner edges.


Note: the script disables selection of any connectors that were previously
selected for the outer edge of the domain to make selection of the inner edges
easier.


Also note: This script potentially generates many warnings, this could cause
the message window to be flooded with warnings if the user has enabled warnings
in the text output.


Options
-------

There are currently only two options/parameters that can be tweaked. These
options can be modified by changing their default values at the top of the
script.

* `verbose`: if this is set to true or one (1) the script will print more
  information to the message window.

* `initializeDomain`: if this is set to true or one (1) the complex domain will
  be initialized by the script after it is created.
