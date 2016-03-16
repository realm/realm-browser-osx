//
//  TGSpreadsheetWriter.m
//  TGSpreadsheetWriter
//
//  Created by Tom Grill on 27.09.12.
//  Copyright (c) 2012 Tom Grill. All rights reserved.
//
/*
 Copyright (c) 2012-2016 Thomas Grill
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
#import "TGSpreadsheetWriter.h"

// Whether the framework was linked dynamically, or via CocoaPods
#if __has_include(<ZipArchive/ZipArchive.h>)
#import <ZipArchive/ZipArchive.h>
#else
#import "SSZipArchive.h"
#endif

@interface TGSpreadsheetWriter()

- (NSString*) ColumnIndexToName:(int) columnIndex;

//Excel Workbook
- (void) ReadSharedStrings: (NSURL*) url;
- (void) ReadData: (NSURL*) url;

- (void) WriteWorksheetData: (NSURL*) outputFile;
- (void) WriteSharedStringsXML: (NSURL*) outputFile;
- (void) WriteWorkbookXML: (NSURL*) outputFile withSheetName:(NSString*)sheetName;

//OpenOffice ODS Format
- (void) WriteODSData: (NSURL*) outputFile;

@end


//************************* SpreadsheetWriter ***************************/
#pragma mark -
@implementation TGSpreadsheetWriter

@synthesize data;
@synthesize sharedStrings;
@synthesize worksheets;
@synthesize tmpDir;

static TGSpreadsheetWriter * spreadsheet = NULL;

-(id) init {
    
    [self setTmpDir: [[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString] stringByAppendingPathComponent:@"ziptmp"]];
    
    //prepare temporary directory
    NSFileManager * fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:spreadsheet.tmpDir]) [fm removeItemAtPath:spreadsheet.tmpDir error:nil];
    [fm createDirectoryAtPath:spreadsheet.tmpDir withIntermediateDirectories:YES attributes:NULL error:Nil];
    
    NSLog(@"Temp. directory initialized:\n %@", tmpDir);
    
    return [super init];
}

/**
 Helper function that returns the name of a column for a specific index
 */
- (NSString*) ColumnIndexToName:(int) columnIndex{
    
    char second = (((int)'A') + columnIndex-1 % 26);
    
    columnIndex /= 26;
    
    NSString * colName = @"";
    
    if (columnIndex == 0)
        colName = [NSString stringWithFormat:@"%s",&second];
    else {
        char v = ((char)(((int)'A') - 1 + columnIndex));
        colName = [NSString stringWithFormat:@"%s%s",&v,&second];
    }
    return colName;
}

//************************* General Methods ***************************/
#pragma mark -
#pragma mark Excel 2004 XML Spreadsheet (xml)
/**
 Excel 2004 XML Spreadsheet
 
 FileEnding: xml
 
 */
+ (NSArray*)readWorksheetXML2004:(NSURL *)input {
    
    NSError * err=NULL;
    NSMutableArray * data = [NSMutableArray new];
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL:input options:NSXMLDocumentTidyXML error:&err];
    
    
    if (!err) {
        
        
        NSString * queryRows = @"/Workbook[1]/Worksheet[1]/Table[1]/Row";
        NSArray * rows = [doc nodesForXPath:queryRows error:&err];
        
        for (NSXMLNode * row in rows){
            
            NSMutableArray * rowData = [NSMutableArray new];
            for (NSXMLNode * cell in row.children){
                NSXMLNode * d = [cell childAtIndex:0];
                [rowData addObject:[d stringValue]];
            }
            [data addObject:rowData];
        }
    } else {
        NSLog(@"%@",[err description]);
    }
    return data;
}

+ (void)writeWorksheetXML2004:(NSURL*)outputFile withData:(NSArray*)data {
    
    int cols = (int)[[data objectAtIndex:0] count];
    int rows = (int)[data count];
    
    
    NSXMLElement * root = [NSXMLElement elementWithName:@"Workbook"];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"urn:schemas-microsoft-com:office:spreadsheet"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:o" stringValue:@"urn:schemas-microsoft-com:office:office"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:x" stringValue:@"urn:schemas-microsoft-com:office:excel"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:ss" stringValue:@"urn:schemas-microsoft-com:office:spreadsheet"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:html" stringValue:@"http://www.w3.org/TR/REC-html40"]];
    
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithRootElement:root];
    [doc setStandalone:YES];
    [doc setCharacterEncoding:@"UTF-8"];
    
    NSXMLElement * ws = [NSXMLElement elementWithName:@"Worksheet"];
    [ws addAttribute:[NSXMLNode attributeWithName:@"ss:Name" stringValue:@"Notes"]];
    [root addChild:ws];
    
    NSXMLElement * t = [NSXMLElement elementWithName:@"Table"];
    [t addAttribute:[NSXMLNode attributeWithName:@"ss:ExpandedColumnCount" stringValue:[NSString stringWithFormat:@"%i",cols]]];
    [t addAttribute:[NSXMLNode attributeWithName:@"ss:ExpandedRowCount" stringValue:[NSString stringWithFormat:@"%i",rows]]];
    [ws addChild:t];
    
    for(NSArray * row in data){
        
        NSXMLElement * r = [NSXMLElement elementWithName:@"Row"];
        [t addChild:r];
        
        for(NSString * cell in row){
            
            NSXMLElement * c = [NSXMLElement elementWithName:@"Cell"];
            [r addChild:c];
            
            NSXMLElement * d = [NSXMLElement elementWithName:@"Data"];
            
            NSNumberFormatter * f = [NSNumberFormatter new];
            NSNumber * n = [f numberFromString:cell];
            
            NSString * type = (n==nil) ? @"String" : @"Number";
            [d addAttribute:[NSXMLNode attributeWithName:@"ss:Type" stringValue:type]];
            [d setStringValue:cell];
            [c addChild:d];
            
            
        }
    }
    //save the xml doc
    bool ok = [[doc XMLDataWithOptions: NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration]
               writeToFile:outputFile.path
               atomically:YES];
    if (!ok) {
        NSBeep();
        NSLog(@"Error when writing file %@", outputFile);
    }
    
}

//************************* General Methods ***************************/
#pragma mark -
#pragma mark Excel Workbook (xlsx)
/**
 Excel Workbook
 
 Format as used by Excel for Mac 2011
 FileEnding: xslx
 */

+ (NSDictionary *)readWorkbook:(NSURL *)inputFile {
    
    if (!spreadsheet) spreadsheet = [TGSpreadsheetWriter new];
    
    //unzip the file
    [SSZipArchive unzipFileAtPath:inputFile.path toDestination:spreadsheet.tmpDir overwrite:YES password:Nil error:Nil];
    
    NSURL * url = [NSURL fileURLWithPath:[spreadsheet.tmpDir stringByAppendingPathComponent:@"xl/sharedStrings.xml"]];
    [spreadsheet ReadSharedStrings:url];
    
    [spreadsheet ReadWorksheets:[NSURL fileURLWithPath:[spreadsheet.tmpDir stringByAppendingPathComponent:@"xl/workbook.xml"]]];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *worksheets = [fileManager contentsOfDirectoryAtPath:[spreadsheet.tmpDir stringByAppendingPathComponent:@"xl/worksheets/"] error:nil];
    
    NSMutableDictionary *workbook = [[NSMutableDictionary alloc] init];
    for (NSString *worksheet in worksheets) {
        if (![worksheet.pathExtension isEqualToString:@"xml"]) {
            continue;
        }
        url = [NSURL fileURLWithPath:[[spreadsheet.tmpDir stringByAppendingPathComponent:@"xl/worksheets/"] stringByAppendingPathComponent:worksheet]];
        [spreadsheet ReadData:url];
        
        NSString *name = spreadsheet.worksheets[worksheet.stringByDeletingPathExtension][@"name"];
        workbook[name] = [spreadsheet data];
    }
    
    return workbook;
}

- (void) ReadSharedStrings: (NSURL*) url {
    
    NSError * err=NULL;
    
    [self setSharedStrings:[NSMutableArray new]];
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                               options:NSXMLDocumentTidyXML error:&err];
    
    if (!err){
        NSString * queryStrings = @"/sst[1]/si/t";
        NSArray * entries = [doc nodesForXPath:queryStrings error:&err];
        
        for (NSXMLNode * e in entries){
            [sharedStrings addObject:[e stringValue]];
        }
    }
    
    
}

- (void) ReadWorksheets: (NSURL*) url {
    
    NSError * err=NULL;
    
    [self setWorksheets:[NSMutableDictionary new]];
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                               options:NSXMLDocumentTidyXML error:&err];
    
    if (!err){
        NSString * querySheets = @"/workbook/sheets/sheet";
        NSArray * sheets = [doc nodesForXPath:querySheets error:&err];
        
        for (NSXMLElement * e in sheets){
            NSMutableDictionary *sheet = [[NSMutableDictionary alloc] init];
            NSString *sheetId = [e attributeForName:@"sheetId"].stringValue;
            NSString *name = [e attributeForName:@"name"].stringValue;
            NSString *state = [e attributeForName:@"state"].stringValue;
            if (name) {
                sheet[@"name"] = name;
            }
            if (sheetId) {
                sheet[@"sheetId"] = sheetId;
            }
            if (state) {
                sheet[@"state"] = state;
            }
            worksheets[[NSString stringWithFormat:@"sheet%@", sheetId]] = sheet;
        }
    }
    
    
}

- (void) ReadData: (NSURL*) url {
    
    NSError * err=NULL;
    [self setData: [NSMutableArray new]];
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                               options:NSXMLDocumentTidyXML error:&err];
    
    
    if (!err){
        
        //get the rows
        NSString * queryRows = @"/worksheet[1]/sheetData[1]/row";
        NSArray * rows = [doc nodesForXPath:queryRows error:&err];
        
        //iterate rows
        for (NSXMLNode * row in rows){
            
            NSMutableArray * newRow = [NSMutableArray new];
            
            //iterate cells
            for (NSXMLElement * cell in [row children]){
                
                NSString * value = NULL;
                if ([[[cell attributeForName:@"t"] stringValue ] isEqualTo:@"s"]){
                    //get shared String
                    int ix = [[[cell childAtIndex:0] stringValue] intValue];
                    value = [spreadsheet.sharedStrings objectAtIndex:ix];
                } else {
                    value = [cell stringValue];
                }
                [newRow addObject:value];
                
            }
            [data addObject:newRow];
        }
        
        
    } else {
        NSLog(@"Error: %@",[err description]);
    }
    
    
}

+ (void)writeWorkbook:(NSURL*) outputFile
              withData:(NSMutableArray*) data
           hasTitleRow:(BOOL) hasTitleRow{
    
    if (!spreadsheet)spreadsheet = [TGSpreadsheetWriter new];
    
    [spreadsheet setData:data];
    
    NSError * err;
    
    //prepare temporary directory
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ziptmp"];
    //NSString * tmpDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/ziptmp"];
    NSString * tmpDirXL = [tmpDir stringByAppendingPathComponent:@"xl"];
    NSString * tmpDirXLWorksheets = [tmpDirXL stringByAppendingPathComponent:@"worksheets"];
    
    if ([fm fileExistsAtPath:tmpDir]){
        [fm removeItemAtPath:tmpDir error:nil];
    }
    
    //[fm createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:NULL error:NIL];
    [fm createDirectoryAtPath:tmpDirXLWorksheets withIntermediateDirectories:YES attributes:NULL error:Nil];
    
    NSString * template = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Template.xlsx"];
    [SSZipArchive unzipFileAtPath:template toDestination:tmpDir overwrite:YES password:Nil error:Nil];
    
    //NSLog(@"Directory <%@> created",tmpDirXL);
    
    //write workbook
    //NSString * tmpDirXLWorkbookPath = [tmpDirXL stringByAppendingPathComponent:@"workbook.xml"];
    //[ExcelReadWrite WriteWorkbookXML: [NSURL fileURLWithPath:tmpDirXLWorkbookPath] withData: data withSheetName:@"sheet1"];
    
    //data rows
    NSString * tmpDirXLSheetPath = [tmpDirXL stringByAppendingPathComponent:@"worksheets/sheet1.xml"];
    [spreadsheet WriteWorksheetData:[NSURL fileURLWithPath:tmpDirXLSheetPath]];
    
    //shared Strings
    NSString * tmpDirXLSharedStringsPath = [tmpDirXL stringByAppendingPathComponent:@"sharedStrings.xml"];
    [spreadsheet WriteSharedStringsXML:[NSURL fileURLWithPath:tmpDirXLSharedStringsPath]];
    
    //list all file contents
    NSArray * files = [fm contentsOfDirectoryAtPath:tmpDir error:&err];
    if (err) {
        NSLog(@"%@",[err description]);
    } else {
        
        //create the zip file
        NSMutableArray * fileArray = [NSMutableArray new];
        for (NSString * fileName in files){
            [fileArray addObject:[tmpDir stringByAppendingPathComponent:fileName]];
        }
        
        [SSZipArchive createZipFileAtPath:outputFile.path withFilesAtPaths:fileArray ];
    }
}

- (void) WriteWorkbookXML: (NSURL*) outputFile withSheetName:(NSString*)sheetName{
    
    NSXMLElement * root = [NSXMLElement elementWithName:@"workbook"];
    [root addAttribute:[NSXMLNode attributeWithName:@"xml:space" stringValue:@"preserve"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"http://schemas.openxmlformats.org/spreadsheetml/2006/main"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:r" stringValue:@"http://schemas.openxmlformats.org/officeDocument/2006/relationships"]];
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithRootElement:root];
    [doc setStandalone:YES];
    
    NSXMLElement * sheets = [NSXMLElement elementWithName:@"sheets"];
    NSXMLElement * sheet = [NSXMLElement elementWithName:@"sheet"];
    [sheet addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:sheetName]];
    [sheets addChild:sheet];
    [root addChild:sheets];
    
    //save the xml doc
    bool ok = [[doc XMLDataWithOptions: NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration]
               writeToFile:outputFile.path
               atomically:YES];
    if (!ok) {
        NSBeep();
        NSLog(@"Error when writing file %@", outputFile);
    }
    
    
}

- (void) WriteSharedStringsXML: (NSURL*) outputFile {
    
    int cols = (int)[sharedStrings count];
    //int rows = (int)[data count];
    
    
    NSXMLElement * root = [NSXMLElement elementWithName:@"sst"];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"http://schemas.openxmlformats.org/spreadsheetml/2006/main"]];
    
    if (cols > 0){
        [root addAttribute:[NSXMLNode attributeWithName:@"count" stringValue:[NSString stringWithFormat:@"%i",cols]]];
        [root addAttribute:[NSXMLNode attributeWithName:@"uniqueCount" stringValue:[NSString stringWithFormat:@"%i",cols]]];
    }
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithRootElement:root];
    [doc setStandalone:YES];
    [doc setCharacterEncoding:@"UTF-8"];
    
    //iterate all columns in the first row
    for (NSString * title in sharedStrings){
        
        NSXMLElement * si = [NSXMLElement elementWithName:@"si"];
        
        [si addChild:[NSXMLElement elementWithName:@"t" stringValue:title]];
        [root addChild:si];
        
    }
    
    //save the xml doc
    bool ok = [[doc XMLDataWithOptions: NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration]
               writeToFile:outputFile.path
               atomically:YES];
    if (!ok) {
        NSBeep();
        NSLog(@"Error when writing file %@", outputFile);
    }
    
}

- (void) WriteWorksheetData: (NSURL*) outputFile {
    
    int cols = (int)[[data objectAtIndex:0] count];
    int rows = (int)[data count];
    
    sharedStrings = [NSMutableArray new];
    
    NSXMLElement * root = [NSXMLElement elementWithName:@"worksheet"];
    /*
     [root addAttribute:[NSXMLNode attributeWithName:@"xml:space" stringValue:@"preserve"]];
     [root addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"http://schemas.microsoft.com/office/excel/2006/2"]];
     [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:r" stringValue:@"http://schemas.openxmlformats.org/officeDocument/2006/relationships"]];
     */
    
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"http://schemas.openxmlformats.org/spreadsheetml/2006/main"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:r" stringValue:@"http://schemas.openxmlformats.org/officeDocument/2006/relationships"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:mc" stringValue:@"http://schemas.openxmlformats.org/markup-compatibility/2006"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:x14ac" stringValue:@"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"mc:Ignorable" stringValue:@"x14ac"]];
    
    
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithRootElement:root];
    //[doc setStringValue:@"<?xml version=1.0"];
    [doc setStandalone:YES];
    [doc setCharacterEncoding:@"UTF-8"];
    
    NSXMLElement * dim = [NSXMLElement elementWithName:@"dimension"];
    
    NSString * activeCell = [NSString stringWithFormat:@"%@%i",[self ColumnIndexToName:cols], rows];
    
    [dim addAttribute:[NSXMLNode attributeWithName:@"ref" stringValue:[NSString stringWithFormat:@"A1:%@",activeCell]]];
    [root addChild:dim];
    
    NSXMLElement * sheetViews = [NSXMLElement elementWithName:@"sheetViews"];
    
    NSXMLElement * sheetView = [NSXMLElement elementWithName:@"sheetView"];
    [sheetView addAttribute:[NSXMLNode attributeWithName:@"tabSelected" stringValue:@"1"]];
    [sheetView addAttribute:[NSXMLNode attributeWithName:@"workbookViewId" stringValue:@"0"]];
    
    NSXMLElement * sel = [NSXMLElement elementWithName:@"selection"];
    [sel addAttribute:[NSXMLNode attributeWithName:@"activeCell" stringValue:activeCell]];
    [sel addAttribute:[NSXMLNode attributeWithName:@"sqref" stringValue:activeCell]];
    
    [sheetView addChild: sel];
    
    
    [sheetViews addChild:sheetView];
    [root addChild:sheetViews];
    
    NSXMLElement * sheetFormatPr = [NSXMLElement elementWithName:@"sheetFormatPr"];
    [sheetFormatPr addAttribute:[NSXMLNode attributeWithName:@"baseColWidth" stringValue:@"10"]];
    [sheetFormatPr addAttribute:[NSXMLNode attributeWithName:@"defaultRowHeight" stringValue:@"15"]];
    [sheetFormatPr addAttribute:[NSXMLNode attributeWithName:@"x14ac:dyDescent" stringValue:@"0"]];
    
    [root addChild:sheetFormatPr];
    
    //data rows
    NSXMLElement * sheetData = [NSXMLElement elementWithName:@"sheetData"];
    
    int rowCounter = 1;
    for(NSArray * row in data){
        
        NSXMLElement * r = [NSXMLElement elementWithName:@"row"];
        [r addAttribute:[NSXMLNode attributeWithName:@"r" stringValue:[NSString stringWithFormat:@"%i",rowCounter]]];
        [r addAttribute:[NSXMLNode attributeWithName:@"spans" stringValue:[NSString stringWithFormat:@"1:%i",cols]]];
        
        [sheetData addChild:r];
        
        int colCounter = 1;
        for(NSString * cell in row){
            
            NSXMLElement * c = [NSXMLElement elementWithName:@"c"];
            NSString * colName = [[spreadsheet ColumnIndexToName:colCounter] stringByAppendingFormat:@"%i",rowCounter];
            NSString * value = cell;
            
            [c addAttribute:[NSXMLNode attributeWithName:@"r" stringValue:colName]];
            
            //check for number
            NSNumberFormatter * f = [NSNumberFormatter new];
            NSNumber * n = [f numberFromString:cell];
            if (!n){
                [c addAttribute:[NSXMLNode attributeWithName:@"t" stringValue:@"s"]];
                
                [sharedStrings addObject:cell];
                value = [NSString stringWithFormat:@"%li",[sharedStrings count]-1];
            }
            [r addChild:c];
            
            [c addChild:[NSXMLElement elementWithName:@"v" stringValue:value]];
            
            colCounter++;
        }
        
        rowCounter++;
    }
    
    [root addChild:sheetData];
    
    NSXMLElement * el = [NSXMLElement elementWithName:@"pageMargins"];
    [el addAttribute:[NSXMLNode attributeWithName:@"left" stringValue:@"0.75"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"right" stringValue:@"0.75"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"top" stringValue:@"1"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"bottom" stringValue:@"0.5"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"header" stringValue:@"0.5"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"footer" stringValue:@"0.5"]];
    [root addChild:el];
    
    NSXMLElement * ext = [NSXMLElement elementWithName:@"extLst"];
    
    el = [NSXMLElement elementWithName:@"ext"];
    [el addAttribute:[NSXMLNode attributeWithName:@"xmlns:mx" stringValue:@"http://schemas.microsoft.com/office/mac/excel/2008/main"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"uri" stringValue:@"{64002731-A6B0-56B0-2670-7721B7C09600}"]];
    
    NSXMLElement * plv = [NSXMLElement elementWithName:@"mx:PLV"];
    [plv addAttribute:[NSXMLNode attributeWithName:@"Mode" stringValue:@"0"]];
    [plv addAttribute:[NSXMLNode attributeWithName:@"OnePage" stringValue:@"0"]];
    [plv addAttribute:[NSXMLNode attributeWithName:@"WScale" stringValue:@"0"]];
    
    [el addChild:plv];
    [ext addChild:el];
    
    [root addChild:ext];
    /*
     <pageMargins left="0.75" right="0.75" top="1" bottom="1" header="0.5" footer="0.5"/>
     <extLst>
     <ext xmlns:mx="http://schemas.microsoft.com/office/mac/excel/2008/main" uri="{64002731-A6B0-56B0-2670-7721B7C09600}">
     <mx:PLV Mode="0" OnePage="0" WScale="0"/>
     </ext>
     </extLst>
     */
    
    //save the xml doc
    bool ok = [[doc XMLDataWithOptions: NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration]
               writeToFile:outputFile.path
               atomically:YES];
    if (!ok) {
        NSBeep();
        NSLog(@"Error when writing file %@", outputFile);
    }
    
}


//************************* General Methods ***************************/
#pragma mark -
#pragma mark OpenOffice/LibreOffice (ods)

/**
 OpenOffice Spreadsheet
 
 Format as used by Openoffice/LibreOffice
 FileEnding: ods
 */

+ (NSArray*)readODS:(NSURL *) inputFile {
    
    NSError * err=NULL;
    NSMutableArray * data = [NSMutableArray new];
    
    if (!spreadsheet) spreadsheet = [TGSpreadsheetWriter new];
    
    //unzip the file
    [SSZipArchive unzipFileAtPath:inputFile.path toDestination:spreadsheet.tmpDir overwrite:YES password:Nil error:Nil];
    
    NSURL * url = [NSURL fileURLWithPath:[spreadsheet.tmpDir stringByAppendingPathComponent:@"content.xml"]];
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                               options:NSXMLDocumentTidyXML error:&err];
    
    if (!err){
        
        //get the rows
        NSString * queryRows = @"/office:document-content[1]/office:body[1]/office:spreadsheet[1]/table:table[1]/table:table-row";
        NSArray * rows = [doc nodesForXPath:queryRows error:&err];
        
        //iterate rows
        for (NSXMLNode * row in rows){
            
            NSMutableArray * newRow = [NSMutableArray new];
            
            //iterate cells
            for (NSXMLElement * cell in [row children]){
                if ([cell attributeForName:@"table:number-columns-repeated"]){
                    
                    int rep = [[[cell attributeForName:@"table:number-columns-repeated"] stringValue] intValue];
                    for (int i = 0; i < rep; i++){
                        [newRow addObject:[cell stringValue]];
                    }
                } else {
                    [newRow addObject:[cell stringValue]];
                }
                
            }
            [data addObject:newRow];
        }
        
        
    } else {
        NSLog(@"Error: %@",[err description]);
    }
    
    return data;
}

+ (void)writeODS: (NSURL*) outputFile
         withData: (NSMutableArray*) data
      hasTitleRow:(BOOL) hasTitleRow{
    
    NSFileManager * fm = [NSFileManager defaultManager];
    
    if (!spreadsheet) spreadsheet = [TGSpreadsheetWriter new];
    
    [spreadsheet setData:data];
    
    NSError * err;
    
    //prepare template
    NSString * template = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Template.ods"];
    [SSZipArchive unzipFileAtPath:template toDestination:spreadsheet.tmpDir overwrite:YES password:Nil error:Nil];
    
    
    //data
    [spreadsheet WriteODSData:[NSURL fileURLWithPath:[spreadsheet.tmpDir stringByAppendingPathComponent:@"content.xml"]]];
    
    
    //zip file
    NSArray * files = [fm contentsOfDirectoryAtPath:[spreadsheet tmpDir] error:&err];
    if (err) {
        NSLog(@"%@",[err description]);
    } else {
        
        //create the zip file
        NSMutableArray * fileArray = [NSMutableArray new];
        for (NSString * fileName in files){
            [fileArray addObject:[spreadsheet.tmpDir stringByAppendingPathComponent:fileName]];
        }
        
        [SSZipArchive createZipFileAtPath:outputFile.path withFilesAtPaths:fileArray ];
    }
}


- (void) WriteODSData: (NSURL*) outputFile
{
    
    NSXMLDocument * doc;
    NSXMLElement * root, *el, *style, *style2;
    
    int cols = (int)[[data objectAtIndex:0] count];
    //int rows = (int)[data count];
    
    //root
    root = [NSXMLElement elementWithName:@"office:document-content"];
    
    doc = [[NSXMLDocument alloc] initWithRootElement:root];
    [doc setStandalone:YES];
    [doc setCharacterEncoding:@"UTF-8"];
    
    //header
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:office" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:office:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:style" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:style:1.00"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:text" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:text:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:table" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:table:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:draw" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:fo" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:xlink" stringValue:@"http://www.w3.org/1999/xlink"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:dc" stringValue:@"http://purl.org/dc/elements/1.1/"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:meta" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:meta:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:meta" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:meta:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:number" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:presentation" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:svg" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:chart" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:chart:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:dr3d" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:math" stringValue:@"http://www.w3.org/1998/Math/MathML"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:form" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:form:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:script" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:script:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:ooo" stringValue:@"http://openoffice.org/2004/office"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:ooow" stringValue:@"http://openoffice.org/2004/writer"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:oooc" stringValue:@"http://openoffice.org/2004/calc"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:dom" stringValue:@"http://www.w3.org/2001/xml-events"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:xforms" stringValue:@"http://www.w3.org/2002/xforms"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:xsd" stringValue:@"http://www.w3.org/2001/XMLSchema"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:rpt" stringValue:@"http://openoffice.org/2005/report"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:rpt" stringValue:@"http://openoffice.org/2005/report"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:of" stringValue:@"urn:oasis:names:tc:opendocument:xmlns:of:1.2"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:html" stringValue:@"http://www.w3.org/1999/xhtml"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:grddl" stringValue:@"http://www.w3.org/2003/g/data-view#"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:tableooo" stringValue:@"http://openoffice.org/2009/table"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:field" stringValue:@"urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:formx" stringValue:@"urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.00"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"xmlns:css3t" stringValue:@"http://www.w3.org/TR/css3-text/"]];
    [root addAttribute:[NSXMLNode attributeWithName:@"office:version" stringValue:@"1.2"]];
    [root addChild:[NSXMLElement elementWithName:@"office:scripts"]];
    
    //style definition
    el = [NSXMLElement elementWithName:@"office:font-face-decls"];
    style = [NSXMLElement elementWithName:@"style:font-face"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:name" stringValue:@"Arial"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"svg:font-family" stringValue:@"Arial"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:font-family-generic" stringValue:@"swiss"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:font-pitch" stringValue:@"variable"]];
    
    [el addChild:style];
    
    style = [NSXMLElement elementWithName:@"style:font-face"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:name" stringValue:@"Arial Unicode MS"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"svg:font-family" stringValue:@"Arial Unicode MS"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:font-family-generic" stringValue:@"system"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:font-pitch" stringValue:@"variable"]];
    
    [el addChild:style];
    
    style = [NSXMLElement elementWithName:@"style:font-face"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:name" stringValue:@"Tahoma"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"svg:font-family" stringValue:@"Tahoma"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:font-family-generic" stringValue:@"system"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:font-pitch" stringValue:@"variable"]];
    
    [el addChild:style];
    
    [root addChild:el];
    
    //automatic styles
    el = [NSXMLElement elementWithName:@"office:automatic-styles"];
    style = [NSXMLElement elementWithName:@"style:style"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:name" stringValue:@"co1"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"svg:family" stringValue:@"table-column"]];
    
    [el addChild:style];
    
    style2 = [NSXMLElement elementWithName:@"style:table-column-properties"];
    [style addAttribute:[NSXMLNode attributeWithName:@"fo:break-before" stringValue:@"auto"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:column-width" stringValue:@"2.258cm"]];
    
    [style addChild:style2];
    
    style = [NSXMLElement elementWithName:@"style:style"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:name" stringValue:@"ro1"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"svg:family" stringValue:@"table-row"]];
    
    [el addChild:style];
    
    style2 = [NSXMLElement elementWithName:@"style:table-row-properties"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:row-height" stringValue:@"0.427cm"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"fo:break-before" stringValue:@"auto"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:use-optimal-row-height" stringValue:@"true"]];
    
    [style addChild:style2];
    
    style = [NSXMLElement elementWithName:@"style:style"];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:name" stringValue:@"ta1"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"svg:family" stringValue:@"table"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:master-page-name" stringValue:@"Default"]];
    
    [el addChild:style];
    
    style2 = [NSXMLElement elementWithName:@"style:table-properties"];
    [style addAttribute:[NSXMLNode attributeWithName:@"table:display" stringValue:@"true"]];
    [style addAttribute:[NSXMLNode attributeWithName:@"style:writing-mode" stringValue:@"lr-tb"]];
    
    [style addChild:style2];
    
    [root addChild:el];
    
    //body
    
    NSXMLElement * body = [NSXMLElement elementWithName:@"office:body"];
    [root addChild: body];
    
    NSXMLElement * sheet = [NSXMLElement elementWithName:@"office:spreadsheet"];
    [body addChild: sheet];
    
    NSXMLElement * table = [NSXMLElement elementWithName:@"table:table"];
    [table addAttribute:[NSXMLNode attributeWithName:@"table:name" stringValue:@"Sheet1"]];
    [table addAttribute:[NSXMLNode attributeWithName:@"table:style-name" stringValue:@"ta1"]];
    
    [sheet addChild:table];
    
    el = [NSXMLElement elementWithName:@"table:table-column"];
    [el addAttribute:[NSXMLNode attributeWithName:@"table:style-name" stringValue:@"co1"]];
    [el addAttribute:[NSXMLNode attributeWithName:@"table:number-columns-repeated" stringValue:[NSString stringWithFormat:@"%i",cols]]];
    [el addAttribute:[NSXMLNode attributeWithName:@"table:default-cell-style-name" stringValue:@"Default"]];
    
    [table addChild:el];
    
    //add rows to table
    int rowCounter = 1;
    for(NSArray * row in data){
        
        NSXMLElement * r = [NSXMLElement elementWithName:@"table:table-row"];
        [r addAttribute:[NSXMLNode attributeWithName:@"table:style-name" stringValue:@"ro1"]];
        
        [table addChild:r];
        
        int colCounter = 1;
        for(NSString * cell in row){
            
            NSXMLElement * c = [NSXMLElement elementWithName:@"table:table-cell"];
            [c addAttribute:[NSXMLNode attributeWithName:@"office:value-type" stringValue:@"string"]];
            
            [r addChild:c];
            [c addChild: [NSXMLElement elementWithName:@"text:p" stringValue:cell]];
            
            colCounter++;
        }
        rowCounter++;
    }
    
    
    //save the xml doc
    bool ok = [[doc XMLDataWithOptions: NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration]
               writeToFile:outputFile.path
               atomically:YES];
    if (!ok) {
        NSBeep();
        NSLog(@"Error when writing file %@", outputFile);
    }
    
}


@end
