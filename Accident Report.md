# Accident Report: Force Push Ảnh Hưởng Đến Pull Requests

## Lý do

Em có chạy `git filter-repo` để xóa file `.env` khỏi lịch sử Git(file không có key , chỉ xoá file mục đích clean). Sau đó dùng `git push --force --all` để đẩy lên remote, vô tình làm ghi đè toàn bộ lịch sử commit cũ.

---

## Step by step

1. Phát hiện file `.env` commit lên Git .
2. Chạy `git filter-repo --path .env --invert-paths` để xóa vĩnh viễn.
3. Dùng `git push --force --all` để đẩy lịch sử mới lên GitHub.
4. Các PR bị đóng do commit SHA thay đổi, không còn liên kết với PR cũ.

---

## Mức độ ảnh hưởng

- **Các PR feature của mọi người** bị đóng | (PR megre vào dev Không cần xử lý lại – code đã có sẵn trong nhánh develop)
- **Các PR Dependabot** cũng bị đóng ( bot sẽ tự tạo lại).
- Code hiện tại vẫn giữ nguyên, chỉ là lịch sử commit bị thay đổi.
- Mọi người đang làm việc trên repo sẽ cần clone lại hoặc reset branch để tránh conflict.

---

## Cách khắc phục

##### Các PR đã được merge vào dev thì không cần push lại

- Với các PR của mọi người,có thể checkout lại commit cũ và push lại branch.

- Với Dependabot: không cần xử lý, bot tự tạo lại sau ạ.
