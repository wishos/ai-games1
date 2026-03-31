#!/usr/bin/env node
// 程序化生成像素角色精灵图
// 用法: node generate_sprite.js knight assets/knight.png

const fs = require('fs');

const args = process.argv.slice(2);
const type = args[0] || 'knight';
const output = args[1] || './sprite.png';

const size = 64;
const canvas = Buffer.alloc(size * size * 4); // RGBA

function setPixel(x, y, r, g, b, a = 255) {
  if (x < 0 || x >= size || y < 0 || y >= size) return;
  const idx = (y * size + x) * 4;
  canvas[idx] = r;
  canvas[idx + 1] = g;
  canvas[idx + 2] = b;
  canvas[idx + 3] = a;
}

function fillRect(x, y, w, h, r, g, b, a = 255) {
  for (let dy = 0; dy < h; dy++) {
    for (let dx = 0; dx < w; dx++) {
      setPixel(x + dx, y + dy, r, g, b, a);
    }
  }
}

// 颜色定义
const COLORS = {
  skin: [232, 200, 160],
  hair: [58, 42, 26],
  cape: [139, 41, 66],
  armor: [74, 106, 138],
  sword: [192, 192, 192],
  gold: [201, 162, 39],
  slime: [90, 170, 90],
  skeleton: [216, 216, 192],
  demon: [170, 34, 68],
};

function drawKnight() {
  // Cape
  fillRect(16, 32, 16, 24, ...COLORS.cape);
  fillRect(12, 40, 8, 16, ...COLORS.cape);
  // Armor body
  fillRect(20, 28, 24, 20, ...COLORS.armor);
  // Head
  fillRect(24, 8, 16, 20, ...COLORS.skin);
  // Hair
  fillRect(24, 4, 16, 10, ...COLORS.hair);
  // Eyes
  setPixel(28, 16, 34, 34, 34);
  setPixel(34, 16, 34, 34, 34);
  // Sword
  fillRect(44, 12, 4, 36, ...COLORS.sword);
  fillRect(40, 16, 12, 4, ...COLORS.gold);
}

function drawSlime() {
  fillRect(16, 40, 32, 16, ...COLORS.slime);
  fillRect(20, 32, 24, 12, ...COLORS.slime);
  // Eyes
  setPixel(26, 40, 68, 255, 68);
  setPixel(36, 40, 68, 255, 68);
}

function drawSkeleton() {
  // Skull
  fillRect(24, 4, 16, 16, ...COLORS.skeleton);
  // Body
  fillRect(24, 20, 16, 24, ...COLORS.skeleton);
  // Eyes
  setPixel(28, 10, 34, 34, 34);
  setPixel(34, 10, 34, 34, 34);
  // Arms
  fillRect(16, 20, 12, 6, ...COLORS.skeleton);
  fillRect(36, 20, 12, 6, ...COLORS.skeleton);
}

function drawDemon() {
  // Body
  fillRect(16, 16, 32, 32, ...COLORS.demon);
  // Horns
  fillRect(12, 4, 10, 16, ...COLORS.demon);
  fillRect(42, 4, 10, 16, ...COLORS.demon);
  // Eyes
  fillRect(22, 24, 8, 8, 255, 100, 100);
  fillRect(34, 24, 8, 8, 255, 100, 100);
}

// 根据类型绘制
if (type === 'knight') drawKnight();
else if (type === 'slime') drawSlime();
else if (type === 'skeleton') drawSkeleton();
else if (type === 'demon') drawDemon();
else drawKnight();

// 创建 PNG
const png = createPNG(size, size, canvas);
fs.writeFileSync(output, png);
console.log(`✅ Saved ${type} sprite to ${output}`);

// 简单PNG编码器
function createPNG(w, h, rgba) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  
  function crc32(buf) {
    let crc = -1;
    for (let i = 0; i < buf.length; i++) {
      crc ^= buf[i];
      for (let j = 0; j < 8; j++) {
        crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
      }
    }
    return (crc ^ -1) >>> 0;
  }
  
  function chunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const typeData = Buffer.concat([Buffer.from(type), data]);
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc32(typeData));
    return Buffer.concat([len, typeData, crcBuf]);
  }
  
  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; // 8-bit RGBA
  
  // IDAT - 未压缩的像素数据
  const rawData = Buffer.alloc(h * (1 + w * 4));
  for (let y = 0; y < h; y++) {
    rawData[y * (1 + w * 4)] = 0; // filter byte
    for (let x = 0; x < w; x++) {
      const src = (y * w + x) * 4;
      const dst = y * (1 + w * 4) + 1 + x * 4;
      rawData[dst] = rgba[src];
      rawData[dst + 1] = rgba[src + 1];
      rawData[dst + 2] = rgba[src + 2];
      rawData[dst + 3] = rgba[src + 3];
    }
  }
  
  // 简单zlib压缩（deflate存储）
  const zlib = require('zlib');
  const compressed = zlib.deflateSync(rawData, { level: 9 });
  
  // IEND
  const iend = Buffer.alloc(0);
  
  return Buffer.concat([
    signature,
    chunk('IHDR', ihdr),
    chunk('IDAT', compressed),
    chunk('IEND', iend)
  ]);
}
