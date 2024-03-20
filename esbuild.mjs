import * as esbuild from "esbuild"
import {sassPlugin} from "esbuild-sass-plugin"
import { readFileSync, writeFileSync, mkdirSync, mkdir } from "fs"
import Mustache from "mustache"
import { Marked } from "marked"
import { markedHighlight } from "marked-highlight"
import hljs from "highlight.js"

const marked = new Marked(
  markedHighlight({
    langPrefix: 'hljs language-',
    highlight(code, lang, info) {
      const language = hljs.getLanguage(lang) ? lang : 'plaintext';
      return hljs.highlight(code, { language }).value;
    }
  })
);

marked.use({gfm: true})

mkdirSync("public", {recursive: true})
writeFileSync("public/index.html",
  Mustache.render(
    readFileSync('src/usage.html', 'utf8'),
    {content: marked.parse(readFileSync('src/usage.md', 'utf8'))}
  ),
  "utf8"
)

export default esbuild.build({
  entryPoints: ["src/crpaste.mjs"],
  bundle: true,
  minify: false,
  outfile: "public/crpaste.min.js",
  plugins: [sassPlugin()],
})