from huggingface_hub import login
from gradio_client import Client

login("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")
client = Client("stachtotalny/fitrpg")


result = client.predict(
    image_url="https://res.cloudinary.com/dxdmkv4bt/image/upload/v1778417007/samples/breakfast.jpg?fbclid=IwY2xjawR73ZNleHRuA2FlbQIxMABicmlkETBYRVZrekl2SzBDdlAwUmlzc3J0YwZhcHBfaWQQMjIyMDM5MTc4ODIwMDg5MgABHlhDS0tqjUTDAn5KltWfaFucvTDA84RcpBDRFU8JsS22KJj6ndx3hsEkSC8v_aem_YWdncwDvVsh1kL6KZyZPjwgOdarx&brid=YWdncwElDjvguJ1MGnEN8LDWyhkY",
    api_name="/predict_health"
)

print(result)
