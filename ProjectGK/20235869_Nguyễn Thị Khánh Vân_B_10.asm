.data 
	message0: .asciz  "Nhập số phần tử của mảng(0<N<21): "
	message1: .asciz  "Nhập số: "
	message2: .asciz  "\nGiá trị phần tử âm lớn nhất: "
	message3: .asciz  "\nVị trí của phần tử âm lớn nhất: "
	message4: .asciz  "Không tồn tại phần tử âm lớn nhất !\n"
	message5: .asciz  "ERROR!\nĐầu vào không hợp lệ\n"
	
	A: .word 20
	
.text
main:
#-------------------------------------------------------------------------------------
# Nhập số phần tử mảng
# Ý nghĩa của các thanh ghi:
#	t0: chỉ số của mảng A
#	t3: số phần tử của mảng số nguyên
#	t4: số phần tử tối đa của mảng A 
#	a1: địa chỉ đầu mảng A 
#	s0: lưu gíá trị phần tử âm lớn nhất -2^31 
#-------------------------------------------------------------------------------------
	li t4, 21 			
	la a1, A			
	li t0, 0			# Chỉ số của mảng A. Khởi tạo i = 0
	li s0, -2147483648		

	li a7, 4		
	la a0, message0
	ecall	
	
	li a7, 5			# Nhập số phần tử mảng
	ecall
	
	addi t3, a0, 0			# Số phần tử của mảng t3 = N
	
	blez t3, error			# n <= 0 -> lỗi
	bge t3, t4, error		# n > 20 -> lỗi
	
	li a7, 4
	la a0, message1
	ecall
	
#---------------------------------------------------------------------------
# Nhập các phần tử của mảng
#---------------------------------------------------------------------------
input:
	beq t0, t3, check		# Nếu đã nhập đủ số phần tử, nhảy đến nhãn check

	li a7, 5			# Nhập các phần tử số vào mảng A
	ecall
	sw a0, 0(a1)			# Thêm số vừa nhập vào mảng A
	
	addi t0, t0, 1			# Tăng chỉ số thêm 1
	addi a1, a1, 4			# 1 phần tử là 4 byte
	
	j input	
	
#----------------------------------------------------------------------------
# Duyệt mảng tìm phần tử âm lớn nhất
# Ý nghĩa các thanh ghi:
#	t0: chỉ số 
#	t1: kiểm tra xem có phần tử âm ko (=1 -> có; = -1 -> không)
#	s1: lưu giá trị từng phần tử trong mảng A
#----------------------------------------------------------------------------
check:
	li t1, -1			# Kiểm tra xem có phần tử âm lớn nhất không
	la a1, A			
	li t0, 0			# Đặt lại chỉ số về 0 để duyệt mảng
	
loop: 
	bge t0, t3, pack		# Kiểm tra duyệt hết các phần tử
	
	lw s1, 0(a1)			# Lấy từng phần tử trong mảng A
	bltz s1, capnhat		# Nếu như s1 < 0 thì mới cập nhật s0
	
	j next				# Nếu s1 >= 0 thì bỏ qua và duyệt tiếp phần tử tiếp theo
	
capnhat:
	blt s1, s0, next		# Kiểm tra s1<s0 thì bỏ qua và duyệt tiếp phần tử tiếp theo
	
	addi s0, s1, 0			# Cập nhật phần tử âm
	li t1, 1			# Cập nhật có tồn tại phần tử âm lớn nhất
	
next:
	addi t0, t0, 1			# Tăng chỉ số, duyệt phần tử kế tiếp
	addi a1, a1, 4
	
	j loop
	
#--------------------------------------------------------------------------------
# Duyệt lại mảng 1 lần nữa
# Để in ra kết quả phần tử âm lớn nhất và tất cả vị trí của nó
#--------------------------------------------------------------------------------
pack:
	bltz t1, end			# Nếu t1 âm -> Không tồn tại phần tử âm lớn nhất
	
	li a7, 4
	la a0, message2			# In chuỗi "Giá trị phần tử âm lớn nhất: "
	ecall
	
	li a7, 1			# In phần tử âm lớn nhất
	addi a0, s0, 0
	ecall
	
	li a7, 4
	la a0, message3			# In chuỗi "Vị trí của phần tử âm lớn nhất:"
	ecall
	
	la a1, A			# Lưu địa chỉ đầu mảng
	li t0, 0			# Đặt lại chỉ số về 0 để duyệt mảng
	
loop1:
	bge t0, t3, exit		# Kiểm tra duyệt hết các phần tử
	
	lw s1, 0(a1)			# Lấy từng phần tử trong mảng A
	bne s1, s0, ship		# Nếu như s1 khác s0 -> duyệt phần tử kế tiếp
	
print:	
	li a7, 1			# In chỉ số của phần tử âm lớn nhất
	addi a0, t0, 0
	ecall
	
	li a7, 11
	li a0, ';'
	ecall
	
ship:
	addi t0, t0, 1			# Tăng chỉ số, duyệt phần tử kế tiếp
	addi a1, a1, 4			# Địa chỉ của phần tử tiếp theo
	
	j loop1
	
end:
	li a7, 4
	la a0, message4			# "Không tồn tại phần tử âm lớn nhất !"
	ecall
	
	j exit 
	
error:
	li a7, 4
	la a0, message5			# "ERROR!\nĐầu vào không hợp lệ"
	ecall
	
exit:
	li a7, 10
	ecall
