# Draft cask for a personal tap (for example thangldw/homebrew-tap/Casks/macinity.rb).
# Not published: the tap repository does not exist yet, and the release is ad-hoc signed and
# not notarized, so Homebrew's official cask repository would reject it.
# On each release, update `version` and `sha256` from release.json (publishedDMGSHA256).
cask "macinity" do
  version "3.2.0"
  sha256 "57aa780a4a3b86af79661fcc78641621fd9f660424d148da0beb52b70eec73e7"

  url "https://github.com/thangldw/macinity/releases/download/v#{version}/Macinity-#{version}.dmg"
  name "Macinity"
  desc "Native macOS monitoring and utilities workspace"
  homepage "https://thangldw.github.io/macinity/"

  depends_on macos: ">= :ventura"

  app "Macinity.app"

  zap trash: [
    "~/Library/Application Support/Toolbox",
    "~/Library/Preferences/com.thang.toolbox.plist",
  ]

  caveats <<~EOS
    Macinity is ad-hoc signed and not notarized. After the first blocked launch, open
    System Settings → Privacy & Security → Open Anyway. Do not disable Gatekeeper.
  EOS
end
