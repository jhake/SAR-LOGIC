read = open("dontuse.txt","r")
write = open("dontuse2.txt","w")
data = read.read().replace('\r\n',' ').replace('HS65','CORE65LPHVT/HS65')

write.write(data)

print data