#!/usr/bin/env bash
# Ghim một bản phát hành vào index.json: tools/pin.sh <id> <vX.Y.Z>
# Lấy SHA COMMIT thật từ GitHub (git ls-remote ... 'refs/tags/<tag>^{}'), chỉ nhận tag annotated.
# Chạy từ thư mục gốc repo sumi-index, rồi tự commit + push.
set -eu
id="${1:-}"; tag="${2:-}"
[[ "$id" =~ ^[a-z][a-z0-9-]{1,31}$ ]] || { echo "dùng: tools/pin.sh <id> <vX.Y.Z>" >&2; exit 2; }
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "tag phải dạng vX.Y.Z" >&2; exit 2; }
command -v jq >/dev/null || { echo "thiếu jq" >&2; exit 1; }
owner="${SUMI_OWNER:-DasNiemand}"
repo="github.com/$owner/sumi-$id"
sha="$(git ls-remote "https://$repo.git" "refs/tags/$tag^{}" | awk '{print $1; exit}')"
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo "không thấy tag annotated $tag ở $repo (đã push tag chưa? tag phải tạo bằng 'git tag -a')" >&2; exit 1; }
f="index.json"; [ -f "$f" ] || echo '{"version":1,"apps":[]}' >"$f"
jq --arg id "$id" --arg repo "$repo" --arg ref "$tag" --arg sha "$sha" \
   '.apps = ((.apps | map(select(.id != $id))) + [{id:$id, repo:$repo, ref:$ref, sha:$sha}] | sort_by(.id))' "$f" >"$f.tmp"
mv "$f.tmp" "$f"
echo "đã ghim $id $tag -> $sha"
echo "kiểm tra, rồi: git add index.json; git commit -m 'pin $id $tag'; git push"
