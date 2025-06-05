.eqv SEVENSEG_RIGHT   0xFFFF0010		# Dia chi cua den led 7 doan phai 
.eqv SEVENSEG_LEFT    0xFFFF0011		# Dia chi cua den led 7 doan trai 
.eqv IN_ADDRESS_HEXA_KEYBOARD   0xFFFF0012  
.eqv OUT_ADDRESS_HEXA_KEYBOARD  0xFFFF0014 
.eqv TIMER_NOW                  0xFFFF0018 
.eqv TIMER_CMP                  0xFFFF0020 
.eqv MASK_CAUSE_TIMER           4 
.eqv MASK_CAUSE_KEYPAD          8      
 
.data 
	A: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F  # Các số từ 0 đến 9
.text 
main: 
	la      t0, handler
	csrrs   zero, utvec, t0 

	li      t1, 0x100
	csrrs   zero, uie, t1     	# uie - ueie bit (bit 8) - external interrupt 
	csrrsi  zero, uie, 0x10   	# uie - utie bit (bit 4) - timer interrupt 
     
	csrrsi  zero, ustatus, 1    	# ustatus - enable uie - global interrupt 
 
# --------------------------------------------------------- 
# Enable interrupts you expect 
# --------------------------------------------------------- 
# Enable the interrupt of keypad of Digital Lab Sim 
	li      t1, IN_ADDRESS_HEXA_KEYBOARD 
	li      t2, 0x80  		# bit 7 of = 1 to enable interrupt    
	sb      t2, 0(t1) 
 
	# Enable the timer interrupt 
	li      t1, TIMER_CMP 
	li      t2, 1000
	sw      t2, 0(t1) 
    
	li s2, 3			# kiểm tra xem nhấn phím nào (3: giây)
	li s4, -1			# lưu phút trước đó để kiểm tra xem đã trôi qua 1 phút chưa
 	
loop:
	nop 
	nop 
	nop 
	j   loop 
end_main: 
# -----------------------------------------------------------------
# Interrupt service routine 
# ----------------------------------------------------------------- 
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
	and     a1, a1, a2      	# Clear interrupt bit to get the value 
     
	li      a2, MASK_CAUSE_TIMER 
	beq     a1, a2, timer_isr 
	li      a2, MASK_CAUSE_KEYPAD 
	beq     a1, a2, keypad_isr 
	j       end_process 
     
timer_isr: 
 	li a7, 30
	ecall           		# a0 = timestamp (ms)
	
	li a1, 0xD13DA400		# tính từ ngày 1/1/1970 đến 15/5/2025 có mã hexa 64bit là 0x196D13DA400 miliseconds
	sub t6, a0, a1			# số mili giây tính từ thời điểm 0:0:0 ngày 15/5/2025

	li s10, 25			# s10: năm -> cố định là 2025

	li s11, 86400000		# 1 ngày = 86400000 mili giây
	div s8, t6, s11 		# s8: ngày

	li s11, 1468800000		# khoảng mili giây từ 15/5 đến 1/6
	beq t6, s11, thang6
	li s9, 5			# s9: tháng -> để tháng hiện tại là tháng 5

	j next
thang6:
	addi s9, s9, 1
	addi s8, s8, -15		# đặt lại mốc về đầu tháng 6

next:
	li s11, 86400000
	mul s11, s11, s8
	sub s11, t6, s11
	li s5, 3600000			# 1 giờ = 3600000 mili giây
	div s5, s11, s5			# s5: giờ
	
	li s11, 24			# một ngày có 24 giờ
	mul s6, s8, s11			# số giờ đã qua trong s8 ngày trước
	add s6, s6, s5			# số giờ đã qua tính đến thời điểm hiện tại
	li s11, 3600000
	mul s11, s6, s11
	sub s11, t6, s11
	li s6, 60000
	div s6, s11, s6			# s6: phut
	
	li s11, 24			
	mul s7, s8, s11
	add s7, s7, s5
	li s11, 60			# một ngày có 60 phút
	mul s7, s7, s11
	add s7, s7, s6
	li s11, 60000			# 1 phút = 60000 mili giây
	mul s7, s7, s11
	sub s7, t6, s7
	li s11, 1000			# 1 giây = 1000 mili giây
	div s7, s7, s11			#s7: giay
	
	beqz s7, phat_am		# nếu như qua phút mới (s7 = 00) -> phát ra âm thanh
	j chon_che_do

phat_am:
	li a0, 60			# nốt nhạc C4
	li a1, 400			# thời gian phát 400 ms
	li a2, 0			# loại nhạc cụ: piano
	li a3, 100			# volume
	li a7, 31
	ecall
	
	li a7, 1
	li a0, 'y'
	ecall

chon_che_do:
# ---- Lấy giá trị tương ứng để hiển thị theo chế độ ----
	li t1, 10			# để lấy 2 số bên trái và phải của led 7 thanh
	la s0, A   			# Lấy địa chỉ đầu tiên của A
	
	li s1, 1
	beq s2, s1, hien_thi_gio	# nếu s1 = 1 (nhấn phím 1) thì hiển thị trên bàn phím giờ hiện tại
	
	li s1, 2
	beq s2, s1, hien_thi_phut	# nếu s1 = 2 (nhấn phím 2) thì hiển thị trên bàn phím phút hiện tại
	
	li s1, 3
	beq s2, s1, hien_thi_giay	# nếu s1 = 3 (nhấn phím 3) thì hiển thị trên bàn phím giờ hiện tại
	
	li s1,4
	beq s2, s1, hien_thi_ngay	# nếu s1 = 4 (nhấn phím 4) thì hiển thị trên bàn phím giây hiện tại
	
	li s1, 5
	beq s2, s1, hien_thi_thang	# nếu s1 = 5 (nhấn phím 5) thì hiển thị trên bàn phím tháng hiện tại
	
	li s1, 6
	beq s2, s1, hien_thi_nam	# nếu s1 = 6 (nhấn phím 6) thì hiển thị trên bàn phím 2 số cuối của năm hiện tại

hien_thi_gio:
	addi s3, s5, 7			# cộng thêm 7 vì việt nam lệch 7 múi giờ
	j show
hien_thi_phut:
	mv s3, s6
	j show
hien_thi_giay:
	mv s3, s7
	j show
hien_thi_ngay:
	addi s3, s8, 15			# vì lấy mốc thời gian là 15/5/2025 nên ngày cần cộng thêm 15
	j show
hien_thi_thang:
	mv s3, s9
	j show
hien_thi_nam:
	mv s3, s10
show:
	div t4, s3, t1
    	add t4, t4, s0       		# Địa chỉ của A[t4]
    	lb a0, 0(t4)         		# set value for segments
    	jal SHOW_7SEG_LEFT  		# show
	
	rem t5, s3, t1
    	add t5, t5, s0        		# Địa chỉ của A[t5]
    	lb a0, 0(t5)          		# set value for segments
    	jal SHOW_7SEG_RIGHT   		# show

	# Set cmp to time + 1000 
	li      a0, TIMER_NOW
	lw      a1, 0(a0)
	addi    a1, a1, 1000
	li      a0, TIMER_CMP
	sw      a1, 0(a0)

	j       end_process

keypad_isr: 

	li      t1, IN_ADDRESS_HEXA_KEYBOARD 
	li      t2, 0x81      		# Check row 1 and re-enable bit 7 
	sb      t2, 0(t1)     		# Must reassign expected row 
	li      t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb      a0, 0(t1)
    
	li t1, 0x00000021		# kiem tra so 1
	beq a0, t1, gio
    
	li t1, 0x00000041		# kiem tra so 2
	beq a0, t1, phut
	
	li t1, 0xFFFFFF81		# kiem tra so 3
	beq a0, t1, giay
    
	li      t1, IN_ADDRESS_HEXA_KEYBOARD 
	li      t2, 0x82      		# Check row 2 and re-enable bit 7 
	sb      t2, 0(t1)     		# Must reassign expected row 
	li      t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb      a0, 0(t1)
    
	li t1, 0x00000012		# kiem tra so 4 
	beq a0, t1, ngay
    
	li t1, 0x00000022 		# kiem tra so 5 
	beq a0, t1, thang
	
	li t1, 0x00000042 		# kiem tra so 6
	beq a0, t1, nam
    
	j end_process 

gio:
	li s2, 1
	j end_process 
phut:
	li s2, 2
	j end_process 
giay:
	li s2, 3
	j end_process
ngay:
	li s2, 4
	j end_process
thang:
	li s2, 5
	j end_process
	
nam:
	li s2, 6
	j end_process
	
#---------------------------------------------------------------
# Chương trình con thực hiện hiển thji số trên led 7 đoạn
#---------------------------------------------------------------
SHOW_7SEG_LEFT:   
    	li t0, SEVENSEG_LEFT   		# assign port's address 
    	sb a0, 0(t0)           		# assign new value   
    	jr ra 
SHOW_7SEG_RIGHT:  
    	li t0, SEVENSEG_RIGHT  		# assign port's address
    	sb a0, 0(t0)           		# assign new value 
    	jr ra  

end_process: 
	lw      a7, 12(sp) 
	lw      a2, 8(sp) 
	lw      a1, 4(sp) 
	lw      a0, 0(sp) 
	addi    sp, sp, 16 
	uret				# quay lại chương trình chính
