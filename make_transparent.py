from PIL import Image

img = Image.open('assets/images/bookwithkhushi_logo.png')
img = img.convert("RGBA")
datas = img.getdata()

newData = []
for item in datas:
    # change all black (also shades of black)
    # to transparent
    if item[0] < 30 and item[1] < 30 and item[2] < 30:
        newData.append((255, 255, 255, 0))
    else:
        newData.append(item)

img.putdata(newData)
img.save("assets/images/bookwithkhushi_logo_transparent.png", "PNG")
print("Done")
