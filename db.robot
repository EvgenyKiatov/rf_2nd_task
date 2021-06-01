*** Settings ***
Test Setup      Test Setup
Test Teardown   Test Teardown
Library         RequestsLibrary     WITH NAME   Req
Library         PostgreSQLDB        WITH NAME   DB
Library         JsonValidator
Library         Collections         WITH NAME   Col
*** Test Cases ***
Check Horizontal Filtering
    ${resp}      Req.GET On Session     alias    /products?        params=select=*,categories(categoryname)
    Log          ${resp.json()}
    ${title}   get elements   ${resp.json()}    $..title
    ${categoryname}   get elements   ${resp.json()}    $..categoryname
    ${params}   create dictionary     title=  categoryname=

    ${SQL}          set variable         SELECT title, categoryname from bootcamp.products,bootcamp.categories where categories.category=products.category
    @{result}    DB.Execute Sql String Mapped  ${SQL}   &{params}
    ${title_db}  create list
    ${category_db}  create list

    FOR   ${k}  IN  @{result}
        Col.Append To List   ${title_db}      ${k}[title]
        Col.Append To List   ${category_db}        ${k}[categoryname]
    END

    Col.Lists Should Be Equal    ${title_db}     ${title}
    Col.Lists Should Be Equal   ${category_db}      ${categoryname}
Check Search One Table
    [teardown]  Delete From DB and Close Connections
    ${j}     create dictionary      categoryname=Arthouse
    Req.POST On Session     alias    /categories?  json=${j}
    ${resp}      Req.GET On Session  alias  /categories?    params=select=*
    log  ${resp.json()}
    ${category}     get elements  ${resp.json()}  $..category
    ${categoryname}     get elements  ${resp.json()}  $..categoryname
    ${SQL}  set variable    select * from bootcamp.categories
    ${params}   create dictionary   category=   categoryname=
    @{result}   DB.Execute Sql String Mapped  ${SQL}    &{params}
    ${category_db}     create list
    ${categoryname_db}     create list
    FOR  ${k}  IN  @{result}
        Col.Append To List    ${category_db}      ${k}[category]
        Col.Append To List     ${categoryname_db}      ${k}[categoryname]
    END
    Col.Lists Should Be Equal   ${category_db}  ${category}
    Col.Lists Should Be Equal   ${categoryname_db}  ${categoryname}


*** Keywords ***
Test Setup
    Req.Create session                   alias       http://localhost:3000
    DB.Connect To Postgresql      hadb    authenticator   password2021dljfklkla1!kljf;    localhost  8432
Test Teardown
    Req.Delete All Sessions
    DB.Disconnect From Postgresql
Delete From DB and Close Connections
    ${del}  set variable  /categories?categoryname=eq.Arthouse
    Req.DELETE On Session   alias   ${del}
    Req.Delete All Sessions
    DB.Disconnect From Postgresql