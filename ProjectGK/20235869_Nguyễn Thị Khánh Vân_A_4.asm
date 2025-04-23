.data 
	message1: .asciz  "Nhập số nguyên dương N: "
	message2: .asciz  "\nKết thúc chương trình"

.text
#--------------------------------------------------------------------
# Nhập số nguyên dương, nếu nhập ký tự chữ hoặc số âm thì kết thúc chương trình
# Ý nghĩa các thanh ghi: 
# 	s0: số nguyên N nhập vào
#	t1: dùng để kiểm tra các ký tự nhập vào với điều kiện (\n, '0', '9')
#	t2: lưu mã ascii của '0' dùng để đổi ký tự số sang số
#	t3: giá trị nhân 10 để tính N
#--------------------------------------------------------------------
input:
	li a7, 4			# In chuỗi "Nhập N"
	la a0, message1
	ecall
	
	li t3, 10			# Giá trị nhân
	li s0, 0			# Biến chứa kết quả số nguyên
	li t2, 48			# Giá trị ASCII của '0'

Check_input:
	li a7, 12			# Đọc 1 ký tự từ bàn phím
	ecall

	li t1, 10			# Kiểm tra nếu là ký tự xuống dòng '\n' -> dừng nhập
	beq a0, t1, main
	
	li t1, 48			# Giá trị ASCII của '0'
	blt a0, t1, exit		# Báo lỗi nếu nhỏ hơn '0' -> kết thúc

	li t1, 57 			# Giá trị ASCII của '9'
	bgt a0, t1, exit		# Báo lỗi nếu lớn hơn '9' -> kết thúc

	sub a0, a0, t2			# Chuyển ký tự thành số 
	mul s0, s0, t3			# Nhân kết quả trước đó với 10
	add s0, s0, a0			# Cộng giá trị số mới vào kết quả
    
	j Check_input			# Lặp lại nhập ký tự tiếp theo

#---------------------------------------------------------------------------------
# Tính tổng các ước (giảm vòng lặp tìm ước xuống sqrt(n) )
# Ý nghĩa các thanh ghi:
#	s0: lưu giá trị các số nhỏ hơn N 
#	s1: tổng các ước
#	s3: được gán giá trị N
#	t0: chỉ số i trong vòng lặp tìm ước của s0 (đồng thời cũng là ước)
#	t1: lưu số căn bậc 2 của s0
#	t2: kết quả phần dư của s0/i
#	t3: lưu ước còn lại 
#	t4,t5: để tìm ra căn bậc 2 của s0
#---------------------------------------------------------------------------------
main:
	addi s3, s0, 0			# s3 == N (số nhập vào)
	li t0, 2
	
	blt s0, t0, exit		# n < 2 -> kết thúc
	li s0, 2
check:
	bge s0, s3, exit		# Bắt đầu lặp từ 2 đến N-1
	li s1, 0			# Tổng các ước 
	li t4, 1			# Chỉ số i của s0 (1<s0<n)
sqrt:
	mul t5, t4, t4			# Phép tính i*i
	bgt t5, s0, loop		# i*i > n
	
	addi t4, t4, 1			# i++
	
	j sqrt
loop:
	li t0, 1			# Chỉ số i của s0
	addi t1, t4, 0			# Căn bậc 2 của s0
loop_check:
	bge t0, t1, check_perfect	# kiểm tra kết quả

	rem t2, s0, t0			# Kiểm tra chia hết s0 % t0
	bnez t2, next			# Nếu không chia hết thì bỏ qua

	add s1, s1, t0			# Nếu là ước, cộng vào tổng

	div t3, s0, t0			# Tìm ước thứ hai: t3 = s0 / t0

	beq t0, t3, next		# Nếu t0 = s0/t0 thì không cộng lại
	beq t3, s0, next 		# Nếu t3 = s0 (tức là ước là chính n)-> bỏ qua 

	add s1, s1, t3 			# Thêm s0/t0 vào tổng

next:
	addi t0, t0, 1			# Tăng chỉ số ước
	j loop_check

#----------------------------------------------
# Kiểm tra tổng ước và hiển thị kết quả
#----------------------------------------------
check_perfect:
	bne s1, s0, Kiem_tra_so_tiep_theo# Kiểm tra nếu s1 khác s0 thì n không là số hoàn hảo
	
	li a7, 1
	addi a0, s0, 0
	ecall
	
	li a7, 11			# In ra khoảng trắng
	li a0, ' '
	ecall
Kiem_tra_so_tiep_theo:
	addi s0, s0, 2
	j check
	
exit:
	li a7, 4			# In chuỗi "Kết thúc chương trình"
	la a0, message2
	ecall
	
	li a7, 11
	li a0, 10
	ecall
	
	li a7, 10
	ecall

