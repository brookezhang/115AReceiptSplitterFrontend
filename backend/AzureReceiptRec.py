import json
import base64
import os
from dotenv import load_dotenv
from flask import Flask, request
from azure.core.exceptions import ResourceNotFoundError
from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import FormTrainingClient
from azure.ai.formrecognizer import FormRecognizerClient

class AzureReceipt:
    def __init__(self):
        pass

    # sets up credentials for Azure api
    # input: NONE 
    # output: azure api object 
    def get_credentials(self):
        load_dotenv()
        API_KEY = os.getenv("API_KEY")
        ENDPOINT = os.getenv("ENDPOINT")
        return FormRecognizerClient(ENDPOINT, AzureKeyCredential(API_KEY))

    # get_receipt(): Converts base64 string to receipt_pic.jpeg file 
    # input: none 
    # output: receipt image file
    def get_receipt(self, img_str):
        with open("./receipt_pic.jpeg","wb") as fh:
            fh.write(base64.b64decode(img_str))

        # open and read image for azure api object
        with open("./receipt_pic.jpeg", "rb") as fd:
            receipt = fd.read()
            return receipt

    # parse_receipt(receipt): runs azure recognizer on receipt image 
    # input: read receipt image file 
    # output: dictionary of receipt objects
    # Used code from this website:
    # https://docs.microsoft.com/en-us/azure/applied-ai-services/form-recognizer/how-to-guides/try-sdk-rest-api?pivots=programming-language-python
    def parse_receipt(self, receipt, form_recognizer_client):
        # scans picture using premade-receipt recoginizer
        poller = form_recognizer_client.begin_recognize_receipts(receipt, locale="en-US")
        result = poller.result()
        item_list = [] # dictionary to hold receipt items and their values

        # loop through list to print and add to dictionaries 
        for receipt in result:
            for name, field in receipt.fields.items():
                if name == "Items":
                    # print("Receipt Items:")
                    for idx, items in enumerate(field.value):
                        entry = {}
                        entry = {}
                        for item_name, item in items.value.items():
                            if item_name == "Name":
                                entry['item_name'] = item.value
                            elif item_name == "TotalPrice":
                                entry['price'] = item.value
                        item_list.append(entry)
                else:
                    if name == "Tax" or name == "Subtotal" or name == "Total" or name == "Tip":
                        ending = {}
                        ending['item_name'] = name
                        ending['price'] = field.value
                        item_list.append(ending)
        return item_list

    # gets receipt image data and parses it 
    def get(self, img_str):
        form_recognizer_client = self.get_credentials()
        receipt = self.get_receipt(img_str) # make b64 string into img file
        items_d = self.parse_receipt(receipt, form_recognizer_client) # run azure api over receipt and return item list
        return json.dumps(items_d)

if __name__ == "__main__":
    img_data = json.load(open('./receipt.json'))
    r = AzureReceipt()
    t = r.get(img_data['img_string'])
    # print(t, 'done')
    