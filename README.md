JML - JSON Manipulation Language
===
A simple interpretted language for performing simple calculations and manipulation on JSON data. Think Excel formulas but with JSON.  

## Compile  
Compile by running `dub`.

## Running your first program  
The following program should be placed in the same directory as the JML executable, unless you wish to modify the shebang.  
```
#!./jml
set /result/
	product
		get /multiplier/;
		get /multiplicand/;
	;
;
```
Then run `sudo chmod +x` on the file.  
You will also need a JSON file to use as a datasource with this program, this program expects both `/multiplier/` and `/multiplicand/` to be in our JSON. We will use the following:  
```
{
	"multiplier": "3",
	"multiplicand": "3"
}
```
When we run our program with the filename of our JSON file as its only argument we will then be presented with the result of our calculation via stdout:
```
{"multiplicand":"3","multiplier":"3","result":9}
```
