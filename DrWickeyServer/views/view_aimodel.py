from inc import *
chunks = ""

# Generating text from neural-chat
def stream(text_input):
    return ollama.chat(model="medllama2",
                         messages=[{'role':'system','content':'you are a doctor'},
                                   {'role':'system', 'content': 'you can give proper medical advice'},
                                   {'role': 'system', 'content': 'create a accurate diagnosis'},
                                   {'role':'system','content':'reply in detail'},
                                   {'role':'user', 'content': text_input}],stream=True)
# main view function
def ai_model():
    exclude = False
    req = request.get_json()
    keyword = req['keyword']
    return gen_text(exclude,keyword), {"Content-Type":'text/event-stream'}


def gen_text(exclude, keyword):
        for chunk in stream(keyword):
            if "[" in chunk['message']['content']:
                exclude = True
                break

            if "]" in chunk['message']['content']:
                exclude = False
                
            if "(" in chunk['message']['content']:
                exclude = True
            if ")" in chunk['message']['content']:
                exclude = False
            
            if not exclude:
                print(chunk['message']['content'])
                yield chunk['message']['content']
        print("#")
        yield "#"