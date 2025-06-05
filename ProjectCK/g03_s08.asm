.eqv SEVENSEG_RIGHT   0xFFFF0010		# địa chỉ của led 7 đoạn phải
.eqv SEVENSEG_LEFT    0xFFFF0011		# địa chỉ của led 7 đoạn trái
.eqv IN_ADDRESS_HEXA_KEYBOARD   0xFFFF0012  	# địa chỉ cổng vào của bàn phím -> quét dòng
.eqv OUT_ADDRESS_HEXA_KEYBOARD  0xFFFF0014 	# địa chỉ cổng ra của bàn phím -> đọc cột
.eqv MASK_CAUSE_KEYPAD          8      	# nguyên nhân ngắt do nhấn phím 
 
.data 
	A: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F    # Chứa mã hiển thị số từ 0–9 cho LED 7 đoạn
	error: .asciz "\nERROR! Không thể chia cho 0 (˘･_･˘)\nHãy tính lại phép tính khác\n"
.text 
main: 
	la      t0, handler
	csrrs   zero, utvec, t0 

	li      t1, 0x100
	csrrs   zero, uie, t1     	# uie - ueie bit (bit 8) - external interrupt 
   
	csrrsi  zero, ustatus, 1    	# ustatus - enable uie - global interrupt 
 
	li      t1, IN_ADDRESS_HEXA_KEYBOARD 
	li      t2, 0x80  		# bit 7 of = 1 to enable interrupt    
	sb      t2, 0(t1) 
 	
 	li s1, 0			# chứa số hiện tại đang nhập
 	li s2, 10			# hệ số nhân -> để tìm số nhấn
 	li s0, 0			# thanh ghi chứa kết quả cuối cùng
 	
 	li t3, 0			# thanh ghi để kiểm tra các điều kiện
 	li t4, 0			# chứa các số từ bàn phím để kiểm tra
 	li s4, 0			# check số đầu tiên
 	li s5, 0			# dấu = -> kiểm tra nếu như không tính tiếp thì reset lại các giá trị 

loop:
	nop 
	nop 
	nop 
	j   loop 
end_main: 
# -------------------------------------------------------------------------
# Interrupt service routine 
# -------------------------------------------------------------------------
handler: 
	# Saves the context 
	addi    sp, sp, -16 
	sw      a0, 0(sp) 
	sw      a1, 4(sp) 
	sw      a2, 8(sp) 
	sw      a7, 12(sp) 
     
	# Handles the interrupt
	csrr    a1, ucause
	li      a2, 0x7FFFFFFF 
	and     a1, a1, a2      		# Clear interrupt bit to get the value 

	li      a2, MASK_CAUSE_KEYPAD 
	beq     a1, a2, keypad_isr 
	j       end_process 

keypad_isr: 

	li t1, IN_ADDRESS_HEXA_KEYBOARD 
	li t2, 0x81      			# Check row 1 and re-enable bit 7 
	sb t2, 0(t1)     			# Must reassign expected row 
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	
	li t1, 0x00000011			# kiem tra so 0
	li t4, 0
	beq a0, t1, capnhat
    
	li t1, 0x00000021			# kiem tra so 1
	li t4, 1
	beq a0, t1, capnhat
    
	li t1, 0x00000041			# kiem tra so 2
	li t4, 2
	beq a0, t1, capnhat
	
	li t1, 0xFFFFFF81			# kiem tra so 3
	li t4, 3
	beq a0, t1, capnhat
    
	li t1, IN_ADDRESS_HEXA_KEYBOARD 
	li t2, 0x82      			# Check row 2 and re-enable bit 7 
	sb t2, 0(t1)     			# Must reassign expected row 
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
    
	li t1, 0x00000012			# kiem tra so 4 
	li t4, 4
	beq a0, t1, capnhat
    
	li t1, 0x00000022 			# kiem tra so 5 
	li t4, 5
	beq a0, t1, capnhat
	
	li t1, 0x00000042 			# kiem tra so 6
	li t4, 6
	beq a0, t1, capnhat
	
	li t1, 0xFFFFFF82
	li t4, 7
	beq a0, t1, capnhat			# kiem tra so 7
	
	li t1, IN_ADDRESS_HEXA_KEYBOARD 
	li t2, 0x84      			# Check row 2 and re-enable bit 7 
	sb t2, 0(t1)     			# Must reassign expected row 
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
    
	li t1, 0x00000014			# kiem tra so 8
	li t4, 8
	beq a0, t1, capnhat
    
	li t1, 0x00000024 			# kiem tra so 9
	li t4, 9
	beq a0, t1, capnhat
	
	li t1, 0x00000044			# kiem tra a (cong +)
	li t4, 10
	beq a0, t1, phep_tinh
	
	li t1, 0xFFFFFF84
	li t4, 11
	beq a0, t1, phep_tinh   		# kiem tra b (tru -)

	li t1, IN_ADDRESS_HEXA_KEYBOARD 
	li t2, 0x88      			# Check row 2 and re-enable bit 7 
	sb t2, 0(t1)     			# Must reassign expected row 
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
    
	li t1, 0x00000018			# kiem tra c (nhan *)
	li t4, 12
	beq a0, t1, phep_tinh
    
	li t1, 0x00000028			# kiem tra d (chia /)
	li t4, 13
	beq a0, t1, phep_tinh
	
	li t1, 0x00000048			# kiem tra e (lay du %)
	li t4, 14
	beq a0, t1, phep_tinh

	li t1, 0xFFFFFF88
	li t4, 15
	beq a0, t1, phep_bang		# kiem tra f (bang =)
	j end_process 
#---------------------------------------------------------------------------------
# Nhập số
# Nhấn các phím 0 – 9, giá trị sẽ được xây dựng dần và hiển thị trên led 7 thanh
# Nếu nhập tiếp tục, chỉ hai chữ số sau cùng được hiển thị
#---------------------------------------------------------------------------------
capnhat:
	bnez s5, reset_all		# Nếu mới nhấn = xong và nhập số mới → tự động reset mọi biến, bắt đầu phép tính mới

new:
	mul s1, s1, s2			# nhân số cũ với 10
	add s1, s1, t4			# cộng tiếp với số vừa nhấn 
	addi s3, s1, 0			# ta được kết quả là số mà mình muốn nhấn (vd: 1234)
	
	j hienthi			# hiển thị giá trị số nhập vào
	
#-----------------------------------------------------------------------------------------------------
# Nhập phép toán
# Sau khi nhập số, bấm phím a đến e để chọn phép toán (+, -, *, /, %)
# Nếu đã có phép toán trước, chương trình sẽ tự động tính phép toán trước đó trước khi cập nhật phép toán mới
#-----------------------------------------------------------------------------------------------------
phep_tinh:
	li a7, 1			# in ra màn hình Run I/O giá trị của số vừa nhập
	mv a0, s1
	ecall

	li s5, 0			# reset s5 khi bắt đầu phép tính mới

	bnez s4, calc_before	   	# kiểm tra xem số vừa nhấn có phải là số đầu tiên không
	mv s0, s1			# nếu là số đầu tiên thì gán cho s0 = s1
	
	j update_op
	
# xử lý phép toán trước đó trước khi cập nhật toán tử mới
calc_before:
	li t3, 10			# kiểm tra dấu trước đó là dấu +
	beq a4, t3, calc_add

	li t3, 11			# kiểm tra dấu trước đó là dấu -
	beq a4, t3, calc_sub
	
	li t3, 12			# kiểm tra dấu trước đó là dấu *
	beq a4, t3, calc_mul
	
	li t3, 13			# kiểm tra dấu trước đó là dấu /
	beq a4, t3, calc_div
	
	li t3, 14			# kiểm tra dấu trước đó là dấu %
	beq a4, t3, calc_rem

	j update_op
	
calc_add:
	add s0, s0, s1			# tính kết quả nếu trước đó là dấu +
	
	j update_op
	
calc_sub:
	sub s0, s0, s1
	
	j update_op
	
calc_mul:
	mul s0, s0, s1
	
	j update_op
	
calc_div:
	beqz s1, chia0_error		# lỗi chia cho 0
	div s0, s0, s1
	
	j update_op
	
calc_rem:
	beqz s1, chia0_error		# lỗi chia cho 0
	rem s0, s0, s1
	
update_op:
	# In ký hiệu toán tử vừa nhấn
	li a7, 11
	
	li t3, 10
	beq t4, t3, print_cong
	
	li t3, 11
   	beq t4, t3, print_tru
   	
	li t3, 12
	beq t4, t3, print_nhan
	
	li t3, 13
	beq t4, t3, print_chia
	
	li t3, 14
	beq t4, t3, print_du
	
	j end_process

print_cong:
	li a0, '+'			# in ra dấu vừa nhấn
	ecall
	
	j set_op
print_tru:
	li a0, '-'
	ecall
	
	j set_op
print_nhan:
	li a0, '*'
	ecall
	
	j set_op
print_chia:
	li a0, '/'
	ecall
	
	j set_op
print_du:
	li a0, '%'
	ecall
set_op:
	li s4, 1          		# Đã có số đầu tiên
	li s1, 0          		# Reset số đang nhập
	mv a4, t4         		# Lưu lại phép toán mới (lưu lại dấu cuối cùng đã nhấn)
	
	j end_process

#---------------------------------------------------------------------------------------
# Nhấn '='
# Thực hiện phép toán cuối cùng và hiển thị kết quả
# Cho phép thực hiện tiếp phép tính mới dựa trên kết quả cũ
#---------------------------------------------------------------------------------------
phep_bang:
	li s5, 1			# vừa mới nhấn '='
	
	li t3, 10			# kiểm tra dấu của phép trước đó là dấu +
	beq a4, t3, cong
	
	li t3, 11
	beq a4, t3, tru

	li t3, 12
	beq a4, t3, nhan
	
	li t3, 13
	beq a4, t3, chia
	
	li t3, 14
	beq a4, t3, du
	
	# nếu như không thực hiện phép tính nào mà nhấn bằng luôn
	li a7, 1			# in ra số đang nhập
	mv a0, s1
	ecall
	
	mv s0, s1			# thanh ghi kết quả được gán bằng số đang nhấn 
	j ketqua			# nhảy đến đây để hiển thị kết quả
cong:
	add s0, s0, s1			# thực hiện phép toán cuối cùng trước khi hiển thị kết quả
	
	li a7, 1			# in ra phần tử số cuối cùng
	mv a0, s1
	ecall

	li s4, 0
	j ketqua
tru:
	sub s0, s0, s1
	
	li a7, 1
	mv a0, s1
	ecall
	
	li s4, 0
	j ketqua
nhan:
	mul s0, s0, s1
	
	li a7, 1
	mv a0, s1
	ecall
	
	li s4, 0
	j ketqua
	
chia:
	beqz s1, chia0_error		# lỗi chia cho 0

	div s0, s0, s1
	
	li a7, 1
	mv a0, s1
	ecall
	
	li s4, 0
	j ketqua
	
du:
	beqz s1, chia0_error		# lỗi chia cho 0
	
	rem s0, s0, s1
	
	li a7, 1
	mv a0, s1
	ecall

ketqua:
	li a7, 11
	li a0, '='
	ecall
	
	li a7, 1			# in ra kết quả vừa tính
	mv a0, s0
	ecall
	
	li a7, 11
	li a0, '\n'
	ecall
	
	mv s3, s0			# hiển thị kết quả khi nhấn =

	mv s1, s0			# gán s1 = s0 để tự động lấy kết quả trước làm toán hạng đầu mà không cần phải nhấn lại
	li a4, 0			# reset thanh ghi chứa dấu của phép toán gần nhất
	
#-------------------------------------------------------------------------------------------------------------
# Hiển thị
# Nếu kết quả dương: hiển thị 2 chữ số cuối cùng
# Nếu kết quả âm: + Nếu số > -10: LED trái hiển thị dấu -, LED phải hiển thị số
# 		  + Nếu số <= -10: chuyển thành số dương rồi hiển thị 2 số cuối
#-------------------------------------------------------------------------------------------------------------
hienthi:
	la a3, A			# lấy địa chỉ đầu mảng A
	
	bge s3, zero, hienthisoduong
	
	sub s3, zero, s3		# nếu số âm <= - 10 thì biến thành số dương để hiển thị 2 số cuối
	
	blt s3, s2, hienthisoam		# nếu như số âm lớn hơn -10 thì nhảy đến hàm này để khi in số âm có cả dấu -
	
hienthisoduong:	
	li t3, 100
	rem s3, s3, t3			# t4 = s3 % 100
	
	li t3, 10

	div t5, s3, t3
    	add t5, t5, a3       		# Địa chỉ của A[t5]
    	lb a0, 0(t5)         		# set value for segments
    	jal SHOW_7SEG_LEFT  		# show
	
	rem t6, s3, t3
    	add t6, t6, a3       		# Địa chỉ của A[t6]
    	lb a0, 0(t6)          		# set value for segments
    	jal SHOW_7SEG_RIGHT   		# show
    	
	j end_process
	
hienthisoam:
	li t3, 10

	li a0, 0x40			# hiển thị dấu -
    	jal SHOW_7SEG_LEFT  		# show
    	
    	rem t6, s3, t3
    	add t6, t6, a3       		# Địa chỉ của A[t6]
    	lb a0, 0(t6)          		# set value for segments
    	jal SHOW_7SEG_RIGHT   		# show
    	
    	j end_process
    	
SHOW_7SEG_LEFT:   
    	li t0, SEVENSEG_LEFT   		# assign port's address 
    	sb a0, 0(t0)           		# assign new value   
    	jr ra 
    	
SHOW_7SEG_RIGHT:  
    	li t0, SEVENSEG_RIGHT  		# assign port's address
    	sb a0, 0(t0)           		# assign new value 
    	jr ra  
    	
reset_all:
	li s1, 0			# reset số đang nhập
	li s0, 0			# reset kết quả
	li s4, 0			# đánh dấu chưa có số đầu tiên
	li s5, 0			# reset trạng thái '='
	
	j new 				# nhảy về chỗ xử lý số
	
#--------------------------------------------------------------------------
# Xử lý chia cho 0
# Nếu chia cho 0, in ra thông báo lỗi và reset lại
#--------------------------------------------------------------------------
chia0_error:
	li a7, 1
	mv a0, s1
	ecall
	
	li a7, 4			# in ra thông báo lỗi
	la a0, error
	ecall
	
	li s0, 0			# reset kết quả về 0
	li s4, 0			# bắt đầu nhập lại số khác
	
end_process: 
	lw      a7, 12(sp) 
	lw      a2, 8(sp) 
	lw      a1, 4(sp) 
	lw      a0, 0(sp) 
	addi    sp, sp, 16 
	uret				# Quay lại chương trình chính
