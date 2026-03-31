## Step by step

1. Phát hiện file `.env` commit lên Git .
2. Chạy `git filter-repo --path .env --invert-paths` để xóa vĩnh viễn.
3. Dùng `git push --force --all` để đẩy lịch sử mới lên GitHub.
4. Các PR bị đóng do commit SHA thay đổi, không còn liên kết với PR cũ.
