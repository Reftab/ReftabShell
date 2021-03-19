ReftabShell
=============

This is a quick and dirty script to interact with the Reftab API via Shell scripts.

# Instructions

### Download repository

Use the [Reftab API documentation](https://www.reftab.com/api-docs) to find endpoints to access.

### Methods
The reftab shell script has 4 flags available.

Parameters each take:
* -e
  * endpoint (e.g. assets, optional parameters may be added such as ?limit=200 to get additional assets)
* -m
  * method (i.e. GET, POST, PUT, DELETE)
* -b
  * body (Needed for PUT or POST, a JSON string)
  * Not needed if you pipe in the JSON.
* -h
  * Prints the help

### Prerequisites

* curl
* openssl
* A valid API key pair from Reftab
  * Generate one in Reftab Settings
  
# Examples

### Get an Asset and Update It

```shell
#This example shows how to get an asset and update it
#For simplicity of parsing and mutating the JSON it will use jq

asset=$(.reftab.sh -m GET -e "assets/NY00")

asset=$(echo $asset | jq '.title="New Title"')

echo $asset | ./reftab.sh -m PUT -e "assets/NY00"
#OR
./reftab.sh -m PUT -e "assets/NY00" -b "${asset}"
```