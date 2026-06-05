class GitWt < Formula
  desc "A fast, interactive git worktree manager"
  homepage "https://github.com/mattmcmanus/git-wt"
  url "https://github.com/mattmcmanus/git-wt/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "d147b176e08c7793cb5c7324f4da5b2230dec379a6b5e70e6c7e3bf0b88e3584"
  license "MIT"

  depends_on "fzf"

  def install
    bin.install "git-wt"
    bash_completion.install "completions/git-wt.bash" => "git-wt"
    zsh_completion.install "completions/git-wt.zsh" => "_git-wt"
  end

  def caveats
    <<~EOS
      git-wt is installed as a git subcommand. Use it with:
        git wt

      For a short alias, create a symlink:
        ln -s #{bin}/git-wt #{bin}/wt
    EOS
  end

  test do
    assert_match "git-wt", shell_output("#{bin}/git-wt version")
  end
end
