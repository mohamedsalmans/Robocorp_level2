*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the image.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Excel.Files
Library             RPA.PDF
Library             Collections
Library             RPA.Desktop
Library             Screenshot
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Variables ***
${Order_Number}     ${EMPTY}
${robot_image}      ${EMPTY}
${Image}            ${EMPTY}
# ${Final Receipt}    ${EMPTY}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the robot orders file, read it as a table, and return the result
    [Teardown]    Close the Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    css: #root > div > div.modal > div > div > div > div > div > button.btn.btn-warning

Download the robot Orders file, read it as a table, and return the result
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True

    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds
        ...    100x
        ...    0.5 sec
        ...    Fill and submit the form for one order
        ...    ${order}
        ${pdf}=    Store the order receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]    ${Image}
        Create receipt PDF with robot preview image    ${pdf}    ${screenshot}    ${order}[Order number]
        Order Another Robot
    END
    Create ZIP file of all orders

Fill and submit the form for one order
    [Arguments]    ${order}
    Wait Until Element Is Visible    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[2]/label

    Select From List By Value
    ...    css: #head
    ...    ${order}[Head]
    Select Radio Button    body    ${order}[Body]

    Input Text
    ...    xpath: /html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    ...    ${order}[Legs]
    Input Text
    ...    css: #address
    ...    ${order}[Address]
    Click Button    Preview
    Click Button    Order
    Wait Until Page Contains    Thank you for your order

Store the order receipt as a PDF file
    [Arguments]    ${Order_Number}

    ${orders_pdf}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${orders_pdf}    ${OUTPUT_DIR}${/}Receipts${/}receipt_${Order_Number}.pdf
    RETURN    ${orders_pdf}

Take a screenshot of the robot
    [Arguments]    ${robot_image}    ${Image}
    ${Image}=    Screenshot
    ...    css: #robot-preview
    ...    ${OUTPUT_DIR}${/}Screenshots${/}Robot_${robot_image}.png
    RETURN    ${Image}

Create receipt PDF with robot preview image
    [Arguments]    ${pdf}    ${screenshot}    ${Order_Number}
    Open Pdf    ${OUTPUT_DIR}${/}Receipts${/}receipt_${Order_Number}.pdf
    ${Final_Receipt}=    Create List    ${OUTPUT_DIR}${/}Screenshots${/}Robot_${Order_Number}.png:align=centre
    Add Files to PDF    ${Final_Receipt}    ${OUTPUT_DIR}${/}Receipts${/}receipt_${Order_Number}.pdf    append=True
    Close Pdf

Order Another Robot
    Click Button    css: #order-another
    Click Button
    ...    css: #root > div > div.modal > div > div > div > div > div > button.btn.btn-warning

Close the Browser
    Close Browser

Create ZIP file of all orders
    ${zip_file}=    Set Variable    ${OUTPUT_DIR}${/}All Receipts ZIP File.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts    ${zip_file}
