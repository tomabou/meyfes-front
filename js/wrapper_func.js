const wasm_test = (edge_array, vertex_array) => {
    const tate = 3;
    const yoko = 4;
    const vertex = new Uint8Array(new Uint32Array(vertex_array).buffer);
    const edge = new Uint8Array(new Uint32Array(edge_array).buffer);
    const vlen = vertex_array.length;
    const elen = edge_array.length;
    const buf_size = vlen * elen * 4;
    const maze_buf = Module._malloc(buf_size * 4);
    Module.ccall("create_maze"
        , "number",
        ["number", "number", "number", "array", "number", "array", "number"],
        [tate, yoko, vlen, vertex, elen, edge, maze_buf])
    const intPtr = Module.HEAP32.subarray(maze_buf / 4, maze_buf / 4 + buf_size);
    const len = intPtr[0];
    console.log(len);
    let ans = [[]];
    let ans_index = 0;
    for (let i = 1; i <= len; i++) {
        const j = intPtr[i];
        if (j === -1) {
            ans.push([]);
            ans_index = ans_index + 1;
            continue;
        }
        ans[ans_index].push(intPtr[i]);
    }
    ans.pop(); ans.pop();
    console.log(ans);
    Module._free(maze_buf);
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