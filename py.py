read = open("dontuse.txt","r")
write = open("dontuse2.txt","w")
data = read.read().replace('\r\n',' ')

write.write(data)

print data