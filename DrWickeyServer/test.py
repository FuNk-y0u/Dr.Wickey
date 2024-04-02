import ollama
modelfile = '''
FROM phi
SYSTEM You are a assistant
SYSTEM Reply in one sentence
'''
ollama.create(model='wickey', modelfile=modelfile)