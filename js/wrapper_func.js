let wrap_create_maze

Module.onRuntimeInitialized = () => {
    wrap_create_maze = Module.cwrap("create_maze"
        , "number",
        ["number", "number", "number", "array", "number", "array", "number"]);
}
const maze_port_func = data => {
    const x = data.x;
    const y = data.y;
    const maze = data.maze;
    console.log(x, y);

    const vertex = [];
    for (let i = 0; i < x; i++) {
        for (let j = 0; j < y; j++) {
            if (maze[i][j] === 0) {
                vertex.push(i);
                vertex.push(j);
            }
        }
    }
    const edge = [];
    for (let i = 0; i < x - 1; i++) {
        for (let j = 0; j < y; j++) {
            if (maze[i][j] === 0 && maze[i + 1][j] === 0) {
                edge.push(i);
                edge.push(j);
                edge.push(i + 1);
                edge.push(j);
            }
        }
    }
    for (let i = 0; i < x; i++) {
        for (let j = 0; j < y - 1; j++) {
            if (maze[i][j] === 0 && maze[i][j + 1] === 0) {
                edge.push(i);
                edge.push(j);
                edge.push(i);
                edge.push(j + 1);
            }
        }
    }
    console.log(vertex);
    console.log(edge);
    const ans = { 'mazelist': run_wasm(x, y, vertex, edge) };

    app.ports.createdMaze.send(ans);
}

const run_wasm = (x, y, vertex_array, edge_array) => {
    const tate = 3;
    const yoko = 4;
    const vertex = new Uint8Array(new Uint32Array(vertex_array).buffer);
    const edge = new Uint8Array(new Uint32Array(edge_array).buffer);
    const vlen = Math.floor(vertex_array.length / 2);
    const elen = Math.floor(edge_array.length / 4);
    const buf_size = (x + 1) * (y + 1) * 16;
    console.log(buf_size);
    console.log(vlen, elen);
    const maze_buf = Module._malloc(buf_size * 4);
    Module.ccall("create_maze"
        , "number",
        ["number", "number", "number", "array", "number", "array", "number"]
        , [tate, yoko, vlen, vertex, elen, edge, maze_buf]);
    const intPtr = Module.HEAP32.subarray(maze_buf / 4, maze_buf / 4 + buf_size);
    const len = intPtr[0];
    let ans = [[]];
    let ans_index = 0;
    for (let i = 1; i <= len; i++) {
        const j = intPtr[i];
        if (j === -1) {
            ans.push([]);
            ans_index = ans_index + 1;
            continue;
        }
        ans[ans_index].push(j);
    }
    console.log(ans);
    ans.pop(); ans.pop();
    Module._free(maze_buf);
    const transpose = a => a[0].map((_, c) => a.map(r => r[c]));
    return transpose(ans.reverse());
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