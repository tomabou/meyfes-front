let wrap_create_maze

Module.onRuntimeInitialized = () => {
    wrap_create_maze = Module.cwrap("create_maze"
        , "number",
        ["number", "number", "number", "array", "number", "array", "number"]);
}


const test_function = () => {
    const canv = document.getElementById('main_canvas');
    const ctx = canv.getContext('2d');
    const imageData = ctx.getImageData(0, 0, canv.width, canv.height);
    console.log(imageData.data.length)
    const data = imageData.data
    for (let i = 0; i < 30; i++) {
        console.log(data[i + 2000]);
    }
}

const get_color_func = (imageData, yoko, tate) => (
    (x, y) => {
        const y_pos = Math.floor((y + 1) * imageData.height / (tate + 1));
        const x_pos = Math.floor((x + 1) * imageData.width / (yoko + 1));
        const red = imageData.data[((y_pos * (imageData.width * 4)) + (x_pos * 4))];
        return red < 230;
    });

const create_edge_list = (vertex, tate, yoko) => {
    const edgeC = []
    for (let i = 0; i < yoko; i++) {
        for (let j = 0; j < tate - 1; j++) {
            if (vertex[i][j] && vertex[i][j + 1]) {
                edgeC.push(i * 1000 + j);
            }
        }
    }
    const edgeR = []
    for (let i = 0; i < yoko - 1; i++) {
        for (let j = 0; j < tate; j++) {
            if (vertex[i][j] && vertex[i + 1][j]) {
                edgeR.push(i * 1000 + j);
            }
        }
    }
    const vertex_list = []
    for (let i = 0; i < yoko; i++) {
        vertex_list.push([])
        for (let j = 0; j < tate; j++) {
            if (vertex[i][j]) {
                vertex_list[i].push(1);
            }
            else {
                vertex_list[i].push(0);
            }
        }
    }

    return [vertex_list, edgeR, edgeC]
}


const create_grid_graph = yoko => {
    const canv = document.getElementById('main_canvas');
    const ctx = canv.getContext('2d');
    const imageData = ctx.getImageData(0, 0, canv.width, canv.height);
    console.log(imageData.data.length);
    const tate = Math.floor(yoko * 3 / 4)
    const get_color = get_color_func(imageData, yoko, tate);
    const vertex = [];
    for (let i = 0; i < yoko; i++) {
        vertex.push([]);
        for (let j = 0; j < tate; j++) {
            vertex[i].push(get_color(i, j));
        }
    }
    const [vertex_list, edgeR, edgeC] = create_edge_list(vertex, tate, yoko);
    const res = {
        "vertex": vertex_list,
        "edgeR": edgeR,
        "edgeC": edgeC
    }
    console.log(res);
    app.ports.gridGraph.send(res);
}

const maze_port_func = data => {
    const x = data.x;
    const y = data.y;
    const maze = data.maze;

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