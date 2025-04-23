.data 
	Digits: .space 50
	message1: .asciz  "Nhập chuỗi A (tối đa 20 ký tự): "
	message2: .asciz  "\nNhập chuỗi B (tối đa 20 ký tự): "
	message3: .asciz  "\nCác ký tự chữ số không xuất hiện cả trong A và B: "

.text 
#---------------------------------------------------------------------------
# Ý nghĩa các thanh ghi:
#	t0: đếm số ký tự nhập vào
#	t4: Đếm số ký tự chữ số trong mảng Digits
#	a1: lưu địa chỉ của đầu mảng Digits
#	s1: lưu số ký tự tối đa của 2 chuỗi A và B
#---------------------------------------------------------------------------
	li t0, 0 			# i = 0
	la a1, Digits 			
	li s1, 20 			
	li t4, 0			
	
    # Nhập chuỗi A
	li a7, 4
	la a0, message1
	ecall
	
	jal loop
	
   # Nhập chuỗi B
	li t0, 0 			# reset lại để nhập chuỗi B
	
	li a7, 4
	la a0, message2
	ecall
	
	jal loop
	
#-------------------------------------------------------------------------------
# Thực hiện việc kiểm tra từng chữ số từ 0 đến 9 có xuất hiện không? bằng cách duyệt từng số một hết mảng Digits rồi duyệt số tiếp theo
# In ra những số không xuất hiện trong cả 2 chuỗi
# Ý nghĩa các thanh ghi:
#	t0: là các số từ 0 đến 9
#	t1: mã ascii của t0
#	t2: chỉ số trong vòng lặp duyệt các ký tự của Digits
#	t3: lưu địa chỉ của các ký tự trong Digits
#	s1: điều kiện dừng kiểm tra t0 (s1 là số 10)
#-------------------------------------------------------------------------------
CHECK:
	li a7, 4
	la a0, message3
	ecall
	
	li t0, 0			# Bắt đầu duyệt từ số 0
	li s1, 10			# duyệt đến 10 thì dừng
	
	beqz t4, print_all		# Không có chữ số nào trong cả 2 chuỗi

check_loop:
	beq t0, s1, end_check		# Duyệt hết các số -> kết thúc
	
	li t2, 0			# Đặt lại chỉ số i = 0 để duyệt
Check_A:
	beq t2, t4, print_digit		# Duyệt hết -> In số không có trong 2 chuỗi
	
	add t3, t2, a1			# Lấy địa chỉ của các ký tự số trong Digits
	lb t5, 0(t3)
	
	addi t1, t0, 48			# Các số từ 0->9
	beq t5, t1, skip_loop		# Nếu xuất hiện thì kiểm tra số tiếp theo
	
	addi t2, t2, 1			# Tăng chỉ số
	
	j Check_A
print_digit:
	li a7, 11 			# In ký tự số ra màn hình
	mv a0, t1			# a0 = mã ascii của số chưa xuất hiện
	ecall

	li a7, 11
	li a0, ';' 			# In dấu ';'
	ecall
	
skip_loop:
	addi t0, t0, 1
	
	j check_loop
	
print_all:
	beq t0, s1, end_check		# In hết các số -> kết thúc

	li a7, 1
	mv a0, t0
	ecall
	
	li a7, 11
	li a0, ';' 			# In dấu ';'
	ecall
	
	addi t0, t0, 1 
	
	j print_all
	
end_check:
	li a7, 11
	li a0, 10 			# In xuống dòng 
	ecall

	li a7, 10			# Kết thúc chương trình
	ecall
	
#---------------------------------------------------------------------------------------
# Chương trình con thực hiện nhập các ký tự của chuỗi A và B
# Nếu như là ký tự chữ số thì cho vào mảng A
#---------------------------------------------------------------------------------------
loop:
	beq t0, s1, end			# Đủ 20 ký tự thì dừng
	
	li a7, 12			# Nhập từng ký tự
	ecall

	li t1, 10			# Kiểm tra nếu là ký tự xuống dòng '\n' -> dừng nhập
	beq a0, t1, end
	
	li t1, 48			# Giá trị ASCII của '0'
	blt a0, t1, skip		# Nếu nhỏ hơn '0' -> bỏ qua

	li t1, 57 			# Giá trị ASCII của '9'
	bgt a0, t1, skip		# Nếu lớn hơn '9' -> bỏ qua
	
	# Lưu toàn bộ chữ số từ cả chuỗi A và B vào chung mảng Digits
	add t1, t4, a1 			# t1 = i + Digits[0]
	sb a0, 0(t1) 			# a0 = Digits[i]
	
	addi t4, t4, 1
	
skip:
	addi t0, t0, 1 			# t0 = t0 + 1 <-> i = i + 1 
	j loop
end:
	jr ra
