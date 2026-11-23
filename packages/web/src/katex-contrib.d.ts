declare module "katex/contrib/copy-tex" {
  export function katexReplaceWithTex(
    fragment: DocumentFragment,
    copyDelimiters?: { inline: [string, string]; display: [string, string] },
  ): DocumentFragment;
}
