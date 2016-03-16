CSwiftV
=======

A csv parser conforming (and tested as much) to [rfc4180](http://tools.ietf.org/html/rfc4180#section-2) i.e the closest thing to a csv spec.

It is currently all in memory so not suitable for very large files.

###TL;DR

```swift
let inputString = "Year,Make,Model,Description,Price\r\n1997,Ford,E350,descrition,3000.00\r\n1999,Chevy,Venture,another description,4900.00\r\n"

let csv = CSwiftV(String: inputString)

let rows = csv.rows // [
                    //  ["1997","Ford","E350","descrition","3000.00"],
                    //  ["1999","Chevy","Venture","another description","4900.00"]
                    // ]

let headers = csv.headers // ["Year","Make","Model","Description","Price"]

let keyedRows = csv.keyedRows // [
                              //  ["Year":"1997","Make":"Ford","Model":"E350","Description":"descrition","Price":"3000.00"],
                              //  ["Year":"1999","Make":"Chevy","Model":"Venture","Description":"another, description","Price":"4900.00"]
                              // ]

```


