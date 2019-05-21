const wasm_test = () => {
    console.log("hello")
    const offset = Module._malloc(20);
    const intPtr = Module.HEAP32.subarray(offset / 4, offset / 4 + 5);
    intPtr[0] = 1;
    intPtr[1] = 2;
    intPtr[2] = 3;
    intPtr[3] = 4;
    intPtr[4] = 5;
    const ans = Module.ccall("test_func", "number", ["number", "number"], [5, offset])
    for (let i = 0; i < 5; i++) {
        console.log(intPtr[i])
    }
    Module._free(offset);

    console.log(ans)
}


const image_port_func = data => {
    const width = 200;
    const img = new Image();
    img.src = data;
    img.onload = () => {
        const elem = document.createElement('canvas');
        const scaleFactor = width / img.width;
        elem.width = width;
        elem.height = img.height * scaleFactor;
        const ctx = elem.getContext('2d');
        ctx.drawImage(img, 0, 0, width, img.height * scaleFactor);
        ctx.canvas.toBlob(function (blob) {
            blob.lastModifiedDate = new Date();
            blob.name = "test";
            // blob to file
            var formdata = new FormData();
            formdata.append("image", blob);

            var xmlhttp = new XMLHttpRequest();
            xmlhttp.onreadystatechange = function () {
                if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                    app.ports.gridGraph.send(JSON.parse(xmlhttp.responseText))
                }
            };
            xmlhttp.open("POST", "https://tomabou.com", true);
            xmlhttp.send(formdata);
        });
    }
}