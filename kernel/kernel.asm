
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	f38080e7          	jalr	-200(ra) # 80002064 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7fc080e7          	jalr	2044(ra) # 800019c0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	140080e7          	jalr	320(ra) # 80002314 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	dfe080e7          	jalr	-514(ra) # 8000200e <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	dc8080e7          	jalr	-568(ra) # 800020ba <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	066080e7          	jalr	102(ra) # 800024ac <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	8c078793          	addi	a5,a5,-1856 # 80021d38 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	c0c080e7          	jalr	-1012(ra) # 800024ac <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	9e8080e7          	jalr	-1560(ra) # 80002314 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e26080e7          	jalr	-474(ra) # 800019a4 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	df4080e7          	jalr	-524(ra) # 800019a4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	de8080e7          	jalr	-536(ra) # 800019a4 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dd0080e7          	jalr	-560(ra) # 800019a4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d90080e7          	jalr	-624(ra) # 800019a4 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d64080e7          	jalr	-668(ra) # 800019a4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	afe080e7          	jalr	-1282(ra) # 80001994 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ae2080e7          	jalr	-1310(ra) # 80001994 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	9e4080e7          	jalr	-1564(ra) # 800028b8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f84080e7          	jalr	-124(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	2c2080e7          	jalr	706(ra) # 800021a6 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	944080e7          	jalr	-1724(ra) # 80002890 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	964080e7          	jalr	-1692(ra) # 800028b8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	eee080e7          	jalr	-274(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	efc080e7          	jalr	-260(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	0d8080e7          	jalr	216(ra) # 80003044 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	768080e7          	jalr	1896(ra) # 800036dc <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	712080e7          	jalr	1810(ra) # 8000468e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	ffe080e7          	jalr	-2(ra) # 80005f82 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d4a080e7          	jalr	-694(ra) # 80001cd6 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e9c48493          	addi	s1,s1,-356 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	282a0a13          	addi	s4,s4,642 # 80017af0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	19048493          	addi	s1,s1,400
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9d050513          	addi	a0,a0,-1584 # 800112c0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9d050513          	addi	a0,a0,-1584 # 800112d8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	dd848493          	addi	s1,s1,-552 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	1b698993          	addi	s3,s3,438 # 80017af0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	f4bc                	sd	a5,104(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	19048493          	addi	s1,s1,400
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
  start_time = ticks;
    80001970:	00007797          	auipc	a5,0x7
    80001974:	6e87a783          	lw	a5,1768(a5) # 80009058 <ticks>
    80001978:	00007717          	auipc	a4,0x7
    8000197c:	6cf72223          	sw	a5,1732(a4) # 8000903c <start_time>
}
    80001980:	70e2                	ld	ra,56(sp)
    80001982:	7442                	ld	s0,48(sp)
    80001984:	74a2                	ld	s1,40(sp)
    80001986:	7902                	ld	s2,32(sp)
    80001988:	69e2                	ld	s3,24(sp)
    8000198a:	6a42                	ld	s4,16(sp)
    8000198c:	6aa2                	ld	s5,8(sp)
    8000198e:	6b02                	ld	s6,0(sp)
    80001990:	6121                	addi	sp,sp,64
    80001992:	8082                	ret

0000000080001994 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000199c:	2501                	sext.w	a0,a0
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
    800019aa:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ac:	2781                	sext.w	a5,a5
    800019ae:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b0:	00010517          	auipc	a0,0x10
    800019b4:	94050513          	addi	a0,a0,-1728 # 800112f0 <cpus>
    800019b8:	953e                	add	a0,a0,a5
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c0:	1101                	addi	sp,sp,-32
    800019c2:	ec06                	sd	ra,24(sp)
    800019c4:	e822                	sd	s0,16(sp)
    800019c6:	e426                	sd	s1,8(sp)
    800019c8:	1000                	addi	s0,sp,32
  push_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	1ce080e7          	jalr	462(ra) # 80000b98 <push_off>
    800019d2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
    800019d8:	00010717          	auipc	a4,0x10
    800019dc:	8e870713          	addi	a4,a4,-1816 # 800112c0 <pid_lock>
    800019e0:	97ba                	add	a5,a5,a4
    800019e2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	254080e7          	jalr	596(ra) # 80000c38 <pop_off>
  return p;
}
    800019ec:	8526                	mv	a0,s1
    800019ee:	60e2                	ld	ra,24(sp)
    800019f0:	6442                	ld	s0,16(sp)
    800019f2:	64a2                	ld	s1,8(sp)
    800019f4:	6105                	addi	sp,sp,32
    800019f6:	8082                	ret

00000000800019f8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e406                	sd	ra,8(sp)
    800019fc:	e022                	sd	s0,0(sp)
    800019fe:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	fc0080e7          	jalr	-64(ra) # 800019c0 <myproc>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>

  if (first) {
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e107a783          	lw	a5,-496(a5) # 80008820 <first.1695>
    80001a18:	eb89                	bnez	a5,80001a2a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1a:	00001097          	auipc	ra,0x1
    80001a1e:	eb6080e7          	jalr	-330(ra) # 800028d0 <usertrapret>
}
    80001a22:	60a2                	ld	ra,8(sp)
    80001a24:	6402                	ld	s0,0(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret
    first = 0;
    80001a2a:	00007797          	auipc	a5,0x7
    80001a2e:	de07ab23          	sw	zero,-522(a5) # 80008820 <first.1695>
    fsinit(ROOTDEV);
    80001a32:	4505                	li	a0,1
    80001a34:	00002097          	auipc	ra,0x2
    80001a38:	c28080e7          	jalr	-984(ra) # 8000365c <fsinit>
    80001a3c:	bff9                	j	80001a1a <forkret+0x22>

0000000080001a3e <allocpid>:
allocpid() {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	e04a                	sd	s2,0(sp)
    80001a48:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a4a:	00010917          	auipc	s2,0x10
    80001a4e:	87690913          	addi	s2,s2,-1930 # 800112c0 <pid_lock>
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	190080e7          	jalr	400(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	dcc78793          	addi	a5,a5,-564 # 80008828 <nextpid>
    80001a64:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a66:	0014871b          	addiw	a4,s1,1
    80001a6a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a6c:	854a                	mv	a0,s2
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	22a080e7          	jalr	554(ra) # 80000c98 <release>
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6902                	ld	s2,0(sp)
    80001a80:	6105                	addi	sp,sp,32
    80001a82:	8082                	ret

0000000080001a84 <proc_pagetable>:
{
    80001a84:	1101                	addi	sp,sp,-32
    80001a86:	ec06                	sd	ra,24(sp)
    80001a88:	e822                	sd	s0,16(sp)
    80001a8a:	e426                	sd	s1,8(sp)
    80001a8c:	e04a                	sd	s2,0(sp)
    80001a8e:	1000                	addi	s0,sp,32
    80001a90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	8a8080e7          	jalr	-1880(ra) # 8000133a <uvmcreate>
    80001a9a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a9c:	c121                	beqz	a0,80001adc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a9e:	4729                	li	a4,10
    80001aa0:	00005697          	auipc	a3,0x5
    80001aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	040005b7          	lui	a1,0x4000
    80001aae:	15fd                	addi	a1,a1,-1
    80001ab0:	05b2                	slli	a1,a1,0xc
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	5fe080e7          	jalr	1534(ra) # 800010b0 <mappages>
    80001aba:	02054863          	bltz	a0,80001aea <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001abe:	4719                	li	a4,6
    80001ac0:	08093683          	ld	a3,128(s2)
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	020005b7          	lui	a1,0x2000
    80001aca:	15fd                	addi	a1,a1,-1
    80001acc:	05b6                	slli	a1,a1,0xd
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	5e0080e7          	jalr	1504(ra) # 800010b0 <mappages>
    80001ad8:	02054163          	bltz	a0,80001afa <proc_pagetable+0x76>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret
    uvmfree(pagetable, 0);
    80001aea:	4581                	li	a1,0
    80001aec:	8526                	mv	a0,s1
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	a48080e7          	jalr	-1464(ra) # 80001536 <uvmfree>
    return 0;
    80001af6:	4481                	li	s1,0
    80001af8:	b7d5                	j	80001adc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afa:	4681                	li	a3,0
    80001afc:	4605                	li	a2,1
    80001afe:	040005b7          	lui	a1,0x4000
    80001b02:	15fd                	addi	a1,a1,-1
    80001b04:	05b2                	slli	a1,a1,0xc
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	76e080e7          	jalr	1902(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b10:	4581                	li	a1,0
    80001b12:	8526                	mv	a0,s1
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	a22080e7          	jalr	-1502(ra) # 80001536 <uvmfree>
    return 0;
    80001b1c:	4481                	li	s1,0
    80001b1e:	bf7d                	j	80001adc <proc_pagetable+0x58>

0000000080001b20 <proc_freepagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	84aa                	mv	s1,a0
    80001b2e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	73a080e7          	jalr	1850(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	724080e7          	jalr	1828(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b5a:	85ca                	mv	a1,s2
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	9d8080e7          	jalr	-1576(ra) # 80001536 <uvmfree>
}
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret

0000000080001b72 <freeproc>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b7e:	6148                	ld	a0,128(a0)
    80001b80:	c509                	beqz	a0,80001b8a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	e76080e7          	jalr	-394(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b8a:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80001b8e:	7ca8                	ld	a0,120(s1)
    80001b90:	c511                	beqz	a0,80001b9c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b92:	78ac                	ld	a1,112(s1)
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	f8c080e7          	jalr	-116(ra) # 80001b20 <proc_freepagetable>
  p->pagetable = 0;
    80001b9c:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80001ba0:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80001ba4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba8:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80001bac:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80001bb0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb8:	0204a623          	sw	zero,44(s1)
  p->last_runnable_time = 0; 	//fcfs timer
    80001bbc:	0204bc23          	sd	zero,56(s1)
  p->mean_ticks = 0;
    80001bc0:	0404b023          	sd	zero,64(s1)
  p->last_ticks = 0;
    80001bc4:	0404b423          	sd	zero,72(s1)
  p->state = UNUSED;
    80001bc8:	0004ac23          	sw	zero,24(s1)
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <allocproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	00010497          	auipc	s1,0x10
    80001be6:	b0e48493          	addi	s1,s1,-1266 # 800116f0 <proc>
    80001bea:	00016917          	auipc	s2,0x16
    80001bee:	f0690913          	addi	s2,s2,-250 # 80017af0 <tickslock>
    acquire(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	ff0080e7          	jalr	-16(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bfc:	4c9c                	lw	a5,24(s1)
    80001bfe:	cf81                	beqz	a5,80001c16 <allocproc+0x40>
      release(&p->lock);
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	096080e7          	jalr	150(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	19048493          	addi	s1,s1,400
    80001c0e:	ff2492e3          	bne	s1,s2,80001bf2 <allocproc+0x1c>
  return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	a051                	j	80001c98 <allocproc+0xc2>
  acquire(&tickslock);
    80001c16:	00016517          	auipc	a0,0x16
    80001c1a:	eda50513          	addi	a0,a0,-294 # 80017af0 <tickslock>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	fc6080e7          	jalr	-58(ra) # 80000be4 <acquire>
  p->last_runnable_time = ticks; 	//save time created for fcfs thingy, tickslock?
    80001c26:	00007797          	auipc	a5,0x7
    80001c2a:	4327e783          	lwu	a5,1074(a5) # 80009058 <ticks>
    80001c2e:	fc9c                	sd	a5,56(s1)
  release(&tickslock);
    80001c30:	00016517          	auipc	a0,0x16
    80001c34:	ec050513          	addi	a0,a0,-320 # 80017af0 <tickslock>
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	060080e7          	jalr	96(ra) # 80000c98 <release>
  p->mean_ticks = 0;
    80001c40:	0404b023          	sd	zero,64(s1)
  p->last_ticks = 0;
    80001c44:	0404b423          	sd	zero,72(s1)
  p->pid = allocpid();
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	df6080e7          	jalr	-522(ra) # 80001a3e <allocpid>
    80001c50:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c52:	4785                	li	a5,1
    80001c54:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	e9e080e7          	jalr	-354(ra) # 80000af4 <kalloc>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	e0c8                	sd	a0,128(s1)
    80001c62:	c131                	beqz	a0,80001ca6 <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e1e080e7          	jalr	-482(ra) # 80001a84 <proc_pagetable>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80001c72:	c531                	beqz	a0,80001cbe <allocproc+0xe8>
  memset(&p->context, 0, sizeof(p->context));
    80001c74:	07000613          	li	a2,112
    80001c78:	4581                	li	a1,0
    80001c7a:	08848513          	addi	a0,s1,136
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	062080e7          	jalr	98(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c86:	00000797          	auipc	a5,0x0
    80001c8a:	d7278793          	addi	a5,a5,-654 # 800019f8 <forkret>
    80001c8e:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c90:	74bc                	ld	a5,104(s1)
    80001c92:	6705                	lui	a4,0x1
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	e8dc                	sd	a5,144(s1)
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	eca080e7          	jalr	-310(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fe6080e7          	jalr	-26(ra) # 80000c98 <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	bff1                	j	80001c98 <allocproc+0xc2>
    freeproc(p);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	eb2080e7          	jalr	-334(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fce080e7          	jalr	-50(ra) # 80000c98 <release>
    return 0;
    80001cd2:	84ca                	mv	s1,s2
    80001cd4:	b7d1                	j	80001c98 <allocproc+0xc2>

0000000080001cd6 <userinit>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	ef6080e7          	jalr	-266(ra) # 80001bd6 <allocproc>
    80001ce8:	84aa                	mv	s1,a0
  initproc = p;
    80001cea:	00007797          	auipc	a5,0x7
    80001cee:	36a7b323          	sd	a0,870(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf2:	03400613          	li	a2,52
    80001cf6:	00007597          	auipc	a1,0x7
    80001cfa:	b3a58593          	addi	a1,a1,-1222 # 80008830 <initcode>
    80001cfe:	7d28                	ld	a0,120(a0)
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	668080e7          	jalr	1640(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d08:	6785                	lui	a5,0x1
    80001d0a:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0c:	60d8                	ld	a4,128(s1)
    80001d0e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d12:	60d8                	ld	a4,128(s1)
    80001d14:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d16:	4641                	li	a2,16
    80001d18:	00006597          	auipc	a1,0x6
    80001d1c:	4e858593          	addi	a1,a1,1256 # 80008200 <digits+0x1c0>
    80001d20:	18048513          	addi	a0,s1,384
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	10e080e7          	jalr	270(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d2c:	00006517          	auipc	a0,0x6
    80001d30:	4e450513          	addi	a0,a0,1252 # 80008210 <digits+0x1d0>
    80001d34:	00002097          	auipc	ra,0x2
    80001d38:	356080e7          	jalr	854(ra) # 8000408a <namei>
    80001d3c:	16a4bc23          	sd	a0,376(s1)
  p->time_state_changed = ticks;
    80001d40:	00007797          	auipc	a5,0x7
    80001d44:	3187a783          	lw	a5,792(a5) # 80009058 <ticks>
    80001d48:	ccfc                	sw	a5,92(s1)
  p->state = RUNNABLE;
    80001d4a:	470d                	li	a4,3
    80001d4c:	cc98                	sw	a4,24(s1)
  p->last_runnable_time = ticks;		//fcfs thingy
    80001d4e:	1782                	slli	a5,a5,0x20
    80001d50:	9381                	srli	a5,a5,0x20
    80001d52:	fc9c                	sd	a5,56(s1)
  release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f42080e7          	jalr	-190(ra) # 80000c98 <release>
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <growproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
    80001d74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c4a080e7          	jalr	-950(ra) # 800019c0 <myproc>
    80001d7e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d80:	792c                	ld	a1,112(a0)
    80001d82:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d86:	00904f63          	bgtz	s1,80001da4 <growproc+0x3c>
  } else if(n < 0){
    80001d8a:	0204cc63          	bltz	s1,80001dc2 <growproc+0x5a>
  p->sz = sz;
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	06c93823          	sd	a2,112(s2)
  return 0;
    80001d96:	4501                	li	a0,0
}
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001da4:	9e25                	addw	a2,a2,s1
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	7d28                	ld	a0,120(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	672080e7          	jalr	1650(ra) # 80001422 <uvmalloc>
    80001db8:	0005061b          	sext.w	a2,a0
    80001dbc:	fa69                	bnez	a2,80001d8e <growproc+0x26>
      return -1;
    80001dbe:	557d                	li	a0,-1
    80001dc0:	bfe1                	j	80001d98 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	7d28                	ld	a0,120(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	60c080e7          	jalr	1548(ra) # 800013da <uvmdealloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	bf55                	j	80001d8e <growproc+0x26>

0000000080001ddc <fork>:
{
    80001ddc:	7179                	addi	sp,sp,-48
    80001dde:	f406                	sd	ra,40(sp)
    80001de0:	f022                	sd	s0,32(sp)
    80001de2:	ec26                	sd	s1,24(sp)
    80001de4:	e84a                	sd	s2,16(sp)
    80001de6:	e44e                	sd	s3,8(sp)
    80001de8:	e052                	sd	s4,0(sp)
    80001dea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	bd4080e7          	jalr	-1068(ra) # 800019c0 <myproc>
    80001df4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	de0080e7          	jalr	-544(ra) # 80001bd6 <allocproc>
    80001dfe:	12050b63          	beqz	a0,80001f34 <fork+0x158>
    80001e02:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e04:	0709b603          	ld	a2,112(s3)
    80001e08:	7d2c                	ld	a1,120(a0)
    80001e0a:	0789b503          	ld	a0,120(s3)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	760080e7          	jalr	1888(ra) # 8000156e <uvmcopy>
    80001e16:	04054663          	bltz	a0,80001e62 <fork+0x86>
  np->sz = p->sz;
    80001e1a:	0709b783          	ld	a5,112(s3)
    80001e1e:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80001e22:	0809b683          	ld	a3,128(s3)
    80001e26:	87b6                	mv	a5,a3
    80001e28:	08093703          	ld	a4,128(s2)
    80001e2c:	12068693          	addi	a3,a3,288
    80001e30:	0007b803          	ld	a6,0(a5)
    80001e34:	6788                	ld	a0,8(a5)
    80001e36:	6b8c                	ld	a1,16(a5)
    80001e38:	6f90                	ld	a2,24(a5)
    80001e3a:	01073023          	sd	a6,0(a4)
    80001e3e:	e708                	sd	a0,8(a4)
    80001e40:	eb0c                	sd	a1,16(a4)
    80001e42:	ef10                	sd	a2,24(a4)
    80001e44:	02078793          	addi	a5,a5,32
    80001e48:	02070713          	addi	a4,a4,32
    80001e4c:	fed792e3          	bne	a5,a3,80001e30 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e50:	08093783          	ld	a5,128(s2)
    80001e54:	0607b823          	sd	zero,112(a5)
    80001e58:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80001e5c:	17800a13          	li	s4,376
    80001e60:	a03d                	j	80001e8e <fork+0xb2>
    freeproc(np);
    80001e62:	854a                	mv	a0,s2
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	d0e080e7          	jalr	-754(ra) # 80001b72 <freeproc>
    release(&np->lock);
    80001e6c:	854a                	mv	a0,s2
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e2a080e7          	jalr	-470(ra) # 80000c98 <release>
    return -1;
    80001e76:	5a7d                	li	s4,-1
    80001e78:	a06d                	j	80001f22 <fork+0x146>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e7a:	00003097          	auipc	ra,0x3
    80001e7e:	8a6080e7          	jalr	-1882(ra) # 80004720 <filedup>
    80001e82:	009907b3          	add	a5,s2,s1
    80001e86:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e88:	04a1                	addi	s1,s1,8
    80001e8a:	01448763          	beq	s1,s4,80001e98 <fork+0xbc>
    if(p->ofile[i])
    80001e8e:	009987b3          	add	a5,s3,s1
    80001e92:	6388                	ld	a0,0(a5)
    80001e94:	f17d                	bnez	a0,80001e7a <fork+0x9e>
    80001e96:	bfcd                	j	80001e88 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e98:	1789b503          	ld	a0,376(s3)
    80001e9c:	00002097          	auipc	ra,0x2
    80001ea0:	9fa080e7          	jalr	-1542(ra) # 80003896 <idup>
    80001ea4:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea8:	4641                	li	a2,16
    80001eaa:	18098593          	addi	a1,s3,384
    80001eae:	18090513          	addi	a0,s2,384
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	f80080e7          	jalr	-128(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001eba:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80001ebe:	854a                	mv	a0,s2
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dd8080e7          	jalr	-552(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ec8:	0000f497          	auipc	s1,0xf
    80001ecc:	41048493          	addi	s1,s1,1040 # 800112d8 <wait_lock>
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	d12080e7          	jalr	-750(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eda:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	db8080e7          	jalr	-584(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ee8:	854a                	mv	a0,s2
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	cfa080e7          	jalr	-774(ra) # 80000be4 <acquire>
  np->running_time = 0;
    80001ef2:	04092c23          	sw	zero,88(s2)
  np->sleeping_time = 0;
    80001ef6:	04092823          	sw	zero,80(s2)
  np->runnable_time = 0;
    80001efa:	04092a23          	sw	zero,84(s2)
  np->time_state_changed = ticks;
    80001efe:	00007797          	auipc	a5,0x7
    80001f02:	15a7a783          	lw	a5,346(a5) # 80009058 <ticks>
    80001f06:	04f92e23          	sw	a5,92(s2)
  np->state = RUNNABLE;
    80001f0a:	470d                	li	a4,3
    80001f0c:	00e92c23          	sw	a4,24(s2)
  np->last_runnable_time = ticks;
    80001f10:	1782                	slli	a5,a5,0x20
    80001f12:	9381                	srli	a5,a5,0x20
    80001f14:	02f93c23          	sd	a5,56(s2)
  release(&np->lock);
    80001f18:	854a                	mv	a0,s2
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d7e080e7          	jalr	-642(ra) # 80000c98 <release>
}
    80001f22:	8552                	mv	a0,s4
    80001f24:	70a2                	ld	ra,40(sp)
    80001f26:	7402                	ld	s0,32(sp)
    80001f28:	64e2                	ld	s1,24(sp)
    80001f2a:	6942                	ld	s2,16(sp)
    80001f2c:	69a2                	ld	s3,8(sp)
    80001f2e:	6a02                	ld	s4,0(sp)
    80001f30:	6145                	addi	sp,sp,48
    80001f32:	8082                	ret
    return -1;
    80001f34:	5a7d                	li	s4,-1
    80001f36:	b7f5                	j	80001f22 <fork+0x146>

0000000080001f38 <sched>:
{
    80001f38:	7179                	addi	sp,sp,-48
    80001f3a:	f406                	sd	ra,40(sp)
    80001f3c:	f022                	sd	s0,32(sp)
    80001f3e:	ec26                	sd	s1,24(sp)
    80001f40:	e84a                	sd	s2,16(sp)
    80001f42:	e44e                	sd	s3,8(sp)
    80001f44:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	a7a080e7          	jalr	-1414(ra) # 800019c0 <myproc>
    80001f4e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c1a080e7          	jalr	-998(ra) # 80000b6a <holding>
    80001f58:	c93d                	beqz	a0,80001fce <sched+0x96>
    80001f5a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f5c:	2781                	sext.w	a5,a5
    80001f5e:	079e                	slli	a5,a5,0x7
    80001f60:	0000f717          	auipc	a4,0xf
    80001f64:	36070713          	addi	a4,a4,864 # 800112c0 <pid_lock>
    80001f68:	97ba                	add	a5,a5,a4
    80001f6a:	0a87a703          	lw	a4,168(a5)
    80001f6e:	4785                	li	a5,1
    80001f70:	06f71763          	bne	a4,a5,80001fde <sched+0xa6>
  if(p->state == RUNNING)
    80001f74:	4c98                	lw	a4,24(s1)
    80001f76:	4791                	li	a5,4
    80001f78:	06f70b63          	beq	a4,a5,80001fee <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f80:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f82:	efb5                	bnez	a5,80001ffe <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f84:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f86:	0000f917          	auipc	s2,0xf
    80001f8a:	33a90913          	addi	s2,s2,826 # 800112c0 <pid_lock>
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	079e                	slli	a5,a5,0x7
    80001f92:	97ca                	add	a5,a5,s2
    80001f94:	0ac7a983          	lw	s3,172(a5)
    80001f98:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f9a:	2781                	sext.w	a5,a5
    80001f9c:	079e                	slli	a5,a5,0x7
    80001f9e:	0000f597          	auipc	a1,0xf
    80001fa2:	35a58593          	addi	a1,a1,858 # 800112f8 <cpus+0x8>
    80001fa6:	95be                	add	a1,a1,a5
    80001fa8:	08848513          	addi	a0,s1,136
    80001fac:	00001097          	auipc	ra,0x1
    80001fb0:	87a080e7          	jalr	-1926(ra) # 80002826 <swtch>
    80001fb4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	97ca                	add	a5,a5,s2
    80001fbc:	0b37a623          	sw	s3,172(a5)
}
    80001fc0:	70a2                	ld	ra,40(sp)
    80001fc2:	7402                	ld	s0,32(sp)
    80001fc4:	64e2                	ld	s1,24(sp)
    80001fc6:	6942                	ld	s2,16(sp)
    80001fc8:	69a2                	ld	s3,8(sp)
    80001fca:	6145                	addi	sp,sp,48
    80001fcc:	8082                	ret
    panic("sched p->lock");
    80001fce:	00006517          	auipc	a0,0x6
    80001fd2:	24a50513          	addi	a0,a0,586 # 80008218 <digits+0x1d8>
    80001fd6:	ffffe097          	auipc	ra,0xffffe
    80001fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>
    panic("sched locks");
    80001fde:	00006517          	auipc	a0,0x6
    80001fe2:	24a50513          	addi	a0,a0,586 # 80008228 <digits+0x1e8>
    80001fe6:	ffffe097          	auipc	ra,0xffffe
    80001fea:	558080e7          	jalr	1368(ra) # 8000053e <panic>
    panic("sched running");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	24a50513          	addi	a0,a0,586 # 80008238 <digits+0x1f8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	24a50513          	addi	a0,a0,586 # 80008248 <digits+0x208>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	538080e7          	jalr	1336(ra) # 8000053e <panic>

000000008000200e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000200e:	7179                	addi	sp,sp,-48
    80002010:	f406                	sd	ra,40(sp)
    80002012:	f022                	sd	s0,32(sp)
    80002014:	ec26                	sd	s1,24(sp)
    80002016:	e84a                	sd	s2,16(sp)
    80002018:	e44e                	sd	s3,8(sp)
    8000201a:	e052                	sd	s4,0(sp)
    8000201c:	1800                	addi	s0,sp,48
    8000201e:	84aa                	mv	s1,a0
    80002020:	892e                	mv	s2,a1
    80002022:	89b2                	mv	s3,a2
    80002024:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	99a080e7          	jalr	-1638(ra) # 800019c0 <myproc>
  if(user_dst){
    8000202e:	c08d                	beqz	s1,80002050 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002030:	86d2                	mv	a3,s4
    80002032:	864e                	mv	a2,s3
    80002034:	85ca                	mv	a1,s2
    80002036:	7d28                	ld	a0,120(a0)
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	63a080e7          	jalr	1594(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002040:	70a2                	ld	ra,40(sp)
    80002042:	7402                	ld	s0,32(sp)
    80002044:	64e2                	ld	s1,24(sp)
    80002046:	6942                	ld	s2,16(sp)
    80002048:	69a2                	ld	s3,8(sp)
    8000204a:	6a02                	ld	s4,0(sp)
    8000204c:	6145                	addi	sp,sp,48
    8000204e:	8082                	ret
    memmove((char *)dst, src, len);
    80002050:	000a061b          	sext.w	a2,s4
    80002054:	85ce                	mv	a1,s3
    80002056:	854a                	mv	a0,s2
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	ce8080e7          	jalr	-792(ra) # 80000d40 <memmove>
    return 0;
    80002060:	8526                	mv	a0,s1
    80002062:	bff9                	j	80002040 <either_copyout+0x32>

0000000080002064 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002064:	7179                	addi	sp,sp,-48
    80002066:	f406                	sd	ra,40(sp)
    80002068:	f022                	sd	s0,32(sp)
    8000206a:	ec26                	sd	s1,24(sp)
    8000206c:	e84a                	sd	s2,16(sp)
    8000206e:	e44e                	sd	s3,8(sp)
    80002070:	e052                	sd	s4,0(sp)
    80002072:	1800                	addi	s0,sp,48
    80002074:	892a                	mv	s2,a0
    80002076:	84ae                	mv	s1,a1
    80002078:	89b2                	mv	s3,a2
    8000207a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	944080e7          	jalr	-1724(ra) # 800019c0 <myproc>
  if(user_src){
    80002084:	c08d                	beqz	s1,800020a6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002086:	86d2                	mv	a3,s4
    80002088:	864e                	mv	a2,s3
    8000208a:	85ca                	mv	a1,s2
    8000208c:	7d28                	ld	a0,120(a0)
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	670080e7          	jalr	1648(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002096:	70a2                	ld	ra,40(sp)
    80002098:	7402                	ld	s0,32(sp)
    8000209a:	64e2                	ld	s1,24(sp)
    8000209c:	6942                	ld	s2,16(sp)
    8000209e:	69a2                	ld	s3,8(sp)
    800020a0:	6a02                	ld	s4,0(sp)
    800020a2:	6145                	addi	sp,sp,48
    800020a4:	8082                	ret
    memmove(dst, (char*)src, len);
    800020a6:	000a061b          	sext.w	a2,s4
    800020aa:	85ce                	mv	a1,s3
    800020ac:	854a                	mv	a0,s2
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	c92080e7          	jalr	-878(ra) # 80000d40 <memmove>
    return 0;
    800020b6:	8526                	mv	a0,s1
    800020b8:	bff9                	j	80002096 <either_copyin+0x32>

00000000800020ba <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800020ba:	715d                	addi	sp,sp,-80
    800020bc:	e486                	sd	ra,72(sp)
    800020be:	e0a2                	sd	s0,64(sp)
    800020c0:	fc26                	sd	s1,56(sp)
    800020c2:	f84a                	sd	s2,48(sp)
    800020c4:	f44e                	sd	s3,40(sp)
    800020c6:	f052                	sd	s4,32(sp)
    800020c8:	ec56                	sd	s5,24(sp)
    800020ca:	e85a                	sd	s6,16(sp)
    800020cc:	e45e                	sd	s7,8(sp)
    800020ce:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800020d0:	00006517          	auipc	a0,0x6
    800020d4:	ff850513          	addi	a0,a0,-8 # 800080c8 <digits+0x88>
    800020d8:	ffffe097          	auipc	ra,0xffffe
    800020dc:	4b0080e7          	jalr	1200(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	79048493          	addi	s1,s1,1936 # 80011870 <proc+0x180>
    800020e8:	00016917          	auipc	s2,0x16
    800020ec:	b8890913          	addi	s2,s2,-1144 # 80017c70 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800020f0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800020f2:	00006997          	auipc	s3,0x6
    800020f6:	16e98993          	addi	s3,s3,366 # 80008260 <digits+0x220>
    printf("%d %s %s", p->pid, state, p->name);
    800020fa:	00006a97          	auipc	s5,0x6
    800020fe:	16ea8a93          	addi	s5,s5,366 # 80008268 <digits+0x228>
    printf("\n");
    80002102:	00006a17          	auipc	s4,0x6
    80002106:	fc6a0a13          	addi	s4,s4,-58 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000210a:	00006b97          	auipc	s7,0x6
    8000210e:	1b6b8b93          	addi	s7,s7,438 # 800082c0 <states.1732>
    80002112:	a00d                	j	80002134 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002114:	eb06a583          	lw	a1,-336(a3)
    80002118:	8556                	mv	a0,s5
    8000211a:	ffffe097          	auipc	ra,0xffffe
    8000211e:	46e080e7          	jalr	1134(ra) # 80000588 <printf>
    printf("\n");
    80002122:	8552                	mv	a0,s4
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	464080e7          	jalr	1124(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000212c:	19048493          	addi	s1,s1,400
    80002130:	03248163          	beq	s1,s2,80002152 <procdump+0x98>
    if(p->state == UNUSED)
    80002134:	86a6                	mv	a3,s1
    80002136:	e984a783          	lw	a5,-360(s1)
    8000213a:	dbed                	beqz	a5,8000212c <procdump+0x72>
      state = "???";
    8000213c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000213e:	fcfb6be3          	bltu	s6,a5,80002114 <procdump+0x5a>
    80002142:	1782                	slli	a5,a5,0x20
    80002144:	9381                	srli	a5,a5,0x20
    80002146:	078e                	slli	a5,a5,0x3
    80002148:	97de                	add	a5,a5,s7
    8000214a:	6390                	ld	a2,0(a5)
    8000214c:	f661                	bnez	a2,80002114 <procdump+0x5a>
      state = "???";
    8000214e:	864e                	mv	a2,s3
    80002150:	b7d1                	j	80002114 <procdump+0x5a>
  }
}
    80002152:	60a6                	ld	ra,72(sp)
    80002154:	6406                	ld	s0,64(sp)
    80002156:	74e2                	ld	s1,56(sp)
    80002158:	7942                	ld	s2,48(sp)
    8000215a:	79a2                	ld	s3,40(sp)
    8000215c:	7a02                	ld	s4,32(sp)
    8000215e:	6ae2                	ld	s5,24(sp)
    80002160:	6b42                	ld	s6,16(sp)
    80002162:	6ba2                	ld	s7,8(sp)
    80002164:	6161                	addi	sp,sp,80
    80002166:	8082                	ret

0000000080002168 <update_process_timing_in_state>:
    // release(&p->lock);
  }
	return kill(cur->pid);
}

void update_process_timing_in_state(struct proc *p, int state){
    80002168:	1141                	addi	sp,sp,-16
    8000216a:	e422                	sd	s0,8(sp)
    8000216c:	0800                	addi	s0,sp,16
  int time_in_ticks = ticks - p->time_state_changed;
    8000216e:	00007717          	auipc	a4,0x7
    80002172:	eea72703          	lw	a4,-278(a4) # 80009058 <ticks>
    80002176:	4d7c                	lw	a5,92(a0)
    80002178:	40f707bb          	subw	a5,a4,a5
  switch (state)
    8000217c:	468d                	li	a3,3
    8000217e:	00d58c63          	beq	a1,a3,80002196 <update_process_timing_in_state+0x2e>
    80002182:	4691                	li	a3,4
    80002184:	00d59d63          	bne	a1,a3,8000219e <update_process_timing_in_state+0x36>
  {
  case RUNNING:
    p->running_time += time_in_ticks;
    80002188:	4d34                	lw	a3,88(a0)
    8000218a:	9fb5                	addw	a5,a5,a3
    8000218c:	cd3c                	sw	a5,88(a0)
    break;
  default:
    p->sleeping_time += time_in_ticks;
    break;
  }
  p->time_state_changed = ticks;
    8000218e:	cd78                	sw	a4,92(a0)
}
    80002190:	6422                	ld	s0,8(sp)
    80002192:	0141                	addi	sp,sp,16
    80002194:	8082                	ret
    p->runnable_time += time_in_ticks;
    80002196:	4974                	lw	a3,84(a0)
    80002198:	9fb5                	addw	a5,a5,a3
    8000219a:	c97c                	sw	a5,84(a0)
    break;
    8000219c:	bfcd                	j	8000218e <update_process_timing_in_state+0x26>
    p->sleeping_time += time_in_ticks;
    8000219e:	4934                	lw	a3,80(a0)
    800021a0:	9fb5                	addw	a5,a5,a3
    800021a2:	c93c                	sw	a5,80(a0)
    break;
    800021a4:	b7ed                	j	8000218e <update_process_timing_in_state+0x26>

00000000800021a6 <scheduler>:
{
    800021a6:	711d                	addi	sp,sp,-96
    800021a8:	ec86                	sd	ra,88(sp)
    800021aa:	e8a2                	sd	s0,80(sp)
    800021ac:	e4a6                	sd	s1,72(sp)
    800021ae:	e0ca                	sd	s2,64(sp)
    800021b0:	fc4e                	sd	s3,56(sp)
    800021b2:	f852                	sd	s4,48(sp)
    800021b4:	f456                	sd	s5,40(sp)
    800021b6:	f05a                	sd	s6,32(sp)
    800021b8:	ec5e                	sd	s7,24(sp)
    800021ba:	e862                	sd	s8,16(sp)
    800021bc:	e466                	sd	s9,8(sp)
    800021be:	1080                	addi	s0,sp,96
    800021c0:	8792                	mv	a5,tp
  int id = r_tp();
    800021c2:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021c4:	00779c93          	slli	s9,a5,0x7
    800021c8:	0000f717          	auipc	a4,0xf
    800021cc:	0f870713          	addi	a4,a4,248 # 800112c0 <pid_lock>
    800021d0:	9766                	add	a4,a4,s9
    800021d2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021d6:	0000f717          	auipc	a4,0xf
    800021da:	12270713          	addi	a4,a4,290 # 800112f8 <cpus+0x8>
    800021de:	9cba                	add	s9,s9,a4
      if(p->state == RUNNABLE && (ticks > cont_timestamp || p->pid == INIT_PROC_PID || p->pid == SHELL_PROC_PID)) {
    800021e0:	00007b97          	auipc	s7,0x7
    800021e4:	e78b8b93          	addi	s7,s7,-392 # 80009058 <ticks>
    800021e8:	00007b17          	auipc	s6,0x7
    800021ec:	e40b0b13          	addi	s6,s6,-448 # 80009028 <cont_timestamp>
        c->proc = p;
    800021f0:	079e                	slli	a5,a5,0x7
    800021f2:	0000fa97          	auipc	s5,0xf
    800021f6:	0cea8a93          	addi	s5,s5,206 # 800112c0 <pid_lock>
    800021fa:	9abe                	add	s5,s5,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002200:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002204:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002208:	0000f497          	auipc	s1,0xf
    8000220c:	4e848493          	addi	s1,s1,1256 # 800116f0 <proc>
      if(p->state == RUNNABLE && (ticks > cont_timestamp || p->pid == INIT_PROC_PID || p->pid == SHELL_PROC_PID)) {
    80002210:	490d                	li	s2,3
        p->state = RUNNING;
    80002212:	4c11                	li	s8,4
    for(p = proc; p < &proc[NPROC]; p++) {
    80002214:	00016a17          	auipc	s4,0x16
    80002218:	8dca0a13          	addi	s4,s4,-1828 # 80017af0 <tickslock>
    8000221c:	a82d                	j	80002256 <scheduler+0xb0>
        update_process_timing_in_state(p, p->state);
    8000221e:	85ca                	mv	a1,s2
    80002220:	8526                	mv	a0,s1
    80002222:	00000097          	auipc	ra,0x0
    80002226:	f46080e7          	jalr	-186(ra) # 80002168 <update_process_timing_in_state>
        p->state = RUNNING;
    8000222a:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    8000222e:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80002232:	08898593          	addi	a1,s3,136
    80002236:	8566                	mv	a0,s9
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	5ee080e7          	jalr	1518(ra) # 80002826 <swtch>
        c->proc = 0;
    80002240:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a52080e7          	jalr	-1454(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000224e:	19048493          	addi	s1,s1,400
    80002252:	fb4485e3          	beq	s1,s4,800021fc <scheduler+0x56>
      acquire(&p->lock);
    80002256:	89a6                	mv	s3,s1
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && (ticks > cont_timestamp || p->pid == INIT_PROC_PID || p->pid == SHELL_PROC_PID)) {
    80002262:	4c9c                	lw	a5,24(s1)
    80002264:	ff2790e3          	bne	a5,s2,80002244 <scheduler+0x9e>
    80002268:	000be703          	lwu	a4,0(s7)
    8000226c:	000b3783          	ld	a5,0(s6)
    80002270:	fae7e7e3          	bltu	a5,a4,8000221e <scheduler+0x78>
    80002274:	589c                	lw	a5,48(s1)
    80002276:	37fd                	addiw	a5,a5,-1
    80002278:	4705                	li	a4,1
    8000227a:	fcf765e3          	bltu	a4,a5,80002244 <scheduler+0x9e>
    8000227e:	b745                	j	8000221e <scheduler+0x78>

0000000080002280 <yield>:
{
    80002280:	1101                	addi	sp,sp,-32
    80002282:	ec06                	sd	ra,24(sp)
    80002284:	e822                	sd	s0,16(sp)
    80002286:	e426                	sd	s1,8(sp)
    80002288:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	736080e7          	jalr	1846(ra) # 800019c0 <myproc>
    80002292:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
  update_process_timing_in_state(p, p->state);
    8000229c:	4c8c                	lw	a1,24(s1)
    8000229e:	8526                	mv	a0,s1
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	ec8080e7          	jalr	-312(ra) # 80002168 <update_process_timing_in_state>
  p->state = RUNNABLE;
    800022a8:	478d                	li	a5,3
    800022aa:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800022ac:	00007797          	auipc	a5,0x7
    800022b0:	dac7e783          	lwu	a5,-596(a5) # 80009058 <ticks>
    800022b4:	fc9c                	sd	a5,56(s1)
  sched();
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	c82080e7          	jalr	-894(ra) # 80001f38 <sched>
  release(&p->lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	9d8080e7          	jalr	-1576(ra) # 80000c98 <release>
}
    800022c8:	60e2                	ld	ra,24(sp)
    800022ca:	6442                	ld	s0,16(sp)
    800022cc:	64a2                	ld	s1,8(sp)
    800022ce:	6105                	addi	sp,sp,32
    800022d0:	8082                	ret

00000000800022d2 <pause_system>:
	if(seconds<=0)
    800022d2:	02a05f63          	blez	a0,80002310 <pause_system+0x3e>
int pause_system(int seconds){
    800022d6:	1141                	addi	sp,sp,-16
    800022d8:	e406                	sd	ra,8(sp)
    800022da:	e022                	sd	s0,0(sp)
    800022dc:	0800                	addi	s0,sp,16
	cont_timestamp = ticks + seconds * 10;
    800022de:	0025179b          	slliw	a5,a0,0x2
    800022e2:	9fa9                	addw	a5,a5,a0
    800022e4:	0017979b          	slliw	a5,a5,0x1
    800022e8:	00007717          	auipc	a4,0x7
    800022ec:	d7072703          	lw	a4,-656(a4) # 80009058 <ticks>
    800022f0:	9fb9                	addw	a5,a5,a4
    800022f2:	1782                	slli	a5,a5,0x20
    800022f4:	9381                	srli	a5,a5,0x20
    800022f6:	00007717          	auipc	a4,0x7
    800022fa:	d2f73923          	sd	a5,-718(a4) # 80009028 <cont_timestamp>
	yield();
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	f82080e7          	jalr	-126(ra) # 80002280 <yield>
	return 1;
    80002306:	4505                	li	a0,1
}
    80002308:	60a2                	ld	ra,8(sp)
    8000230a:	6402                	ld	s0,0(sp)
    8000230c:	0141                	addi	sp,sp,16
    8000230e:	8082                	ret
		return 0;
    80002310:	4501                	li	a0,0
}
    80002312:	8082                	ret

0000000080002314 <sleep>:
{
    80002314:	7179                	addi	sp,sp,-48
    80002316:	f406                	sd	ra,40(sp)
    80002318:	f022                	sd	s0,32(sp)
    8000231a:	ec26                	sd	s1,24(sp)
    8000231c:	e84a                	sd	s2,16(sp)
    8000231e:	e44e                	sd	s3,8(sp)
    80002320:	1800                	addi	s0,sp,48
    80002322:	89aa                	mv	s3,a0
    80002324:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	69a080e7          	jalr	1690(ra) # 800019c0 <myproc>
    8000232e:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  release(lk);
    80002338:	854a                	mv	a0,s2
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	95e080e7          	jalr	-1698(ra) # 80000c98 <release>
  p->chan = chan;
    80002342:	0334b023          	sd	s3,32(s1)
  update_process_timing_in_state(p, p->state);
    80002346:	4c8c                	lw	a1,24(s1)
    80002348:	8526                	mv	a0,s1
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	e1e080e7          	jalr	-482(ra) # 80002168 <update_process_timing_in_state>
  p->state = SLEEPING;
    80002352:	4789                	li	a5,2
    80002354:	cc9c                	sw	a5,24(s1)
  sched();
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	be2080e7          	jalr	-1054(ra) # 80001f38 <sched>
  p->chan = 0;
    8000235e:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
  acquire(lk);
    8000236c:	854a                	mv	a0,s2
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	876080e7          	jalr	-1930(ra) # 80000be4 <acquire>
}
    80002376:	70a2                	ld	ra,40(sp)
    80002378:	7402                	ld	s0,32(sp)
    8000237a:	64e2                	ld	s1,24(sp)
    8000237c:	6942                	ld	s2,16(sp)
    8000237e:	69a2                	ld	s3,8(sp)
    80002380:	6145                	addi	sp,sp,48
    80002382:	8082                	ret

0000000080002384 <wait>:
{
    80002384:	715d                	addi	sp,sp,-80
    80002386:	e486                	sd	ra,72(sp)
    80002388:	e0a2                	sd	s0,64(sp)
    8000238a:	fc26                	sd	s1,56(sp)
    8000238c:	f84a                	sd	s2,48(sp)
    8000238e:	f44e                	sd	s3,40(sp)
    80002390:	f052                	sd	s4,32(sp)
    80002392:	ec56                	sd	s5,24(sp)
    80002394:	e85a                	sd	s6,16(sp)
    80002396:	e45e                	sd	s7,8(sp)
    80002398:	e062                	sd	s8,0(sp)
    8000239a:	0880                	addi	s0,sp,80
    8000239c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	622080e7          	jalr	1570(ra) # 800019c0 <myproc>
    800023a6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a8:	0000f517          	auipc	a0,0xf
    800023ac:	f3050513          	addi	a0,a0,-208 # 800112d8 <wait_lock>
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
    havekids = 0;
    800023b8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023ba:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023bc:	00015997          	auipc	s3,0x15
    800023c0:	73498993          	addi	s3,s3,1844 # 80017af0 <tickslock>
        havekids = 1;
    800023c4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c6:	0000fc17          	auipc	s8,0xf
    800023ca:	f12c0c13          	addi	s8,s8,-238 # 800112d8 <wait_lock>
    havekids = 0;
    800023ce:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023d0:	0000f497          	auipc	s1,0xf
    800023d4:	32048493          	addi	s1,s1,800 # 800116f0 <proc>
    800023d8:	a0bd                	j	80002446 <wait+0xc2>
          pid = np->pid;
    800023da:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023de:	000b0e63          	beqz	s6,800023fa <wait+0x76>
    800023e2:	4691                	li	a3,4
    800023e4:	02c48613          	addi	a2,s1,44
    800023e8:	85da                	mv	a1,s6
    800023ea:	07893503          	ld	a0,120(s2)
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	284080e7          	jalr	644(ra) # 80001672 <copyout>
    800023f6:	02054563          	bltz	a0,80002420 <wait+0x9c>
          freeproc(np);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	776080e7          	jalr	1910(ra) # 80001b72 <freeproc>
          release(&np->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	892080e7          	jalr	-1902(ra) # 80000c98 <release>
          release(&wait_lock);
    8000240e:	0000f517          	auipc	a0,0xf
    80002412:	eca50513          	addi	a0,a0,-310 # 800112d8 <wait_lock>
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	882080e7          	jalr	-1918(ra) # 80000c98 <release>
          return pid;
    8000241e:	a09d                	j	80002484 <wait+0x100>
            release(&np->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
            release(&wait_lock);
    8000242a:	0000f517          	auipc	a0,0xf
    8000242e:	eae50513          	addi	a0,a0,-338 # 800112d8 <wait_lock>
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
            return -1;
    8000243a:	59fd                	li	s3,-1
    8000243c:	a0a1                	j	80002484 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000243e:	19048493          	addi	s1,s1,400
    80002442:	03348463          	beq	s1,s3,8000246a <wait+0xe6>
      if(np->parent == p){
    80002446:	70bc                	ld	a5,96(s1)
    80002448:	ff279be3          	bne	a5,s2,8000243e <wait+0xba>
        acquire(&np->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002456:	4c9c                	lw	a5,24(s1)
    80002458:	f94781e3          	beq	a5,s4,800023da <wait+0x56>
        release(&np->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	83a080e7          	jalr	-1990(ra) # 80000c98 <release>
        havekids = 1;
    80002466:	8756                	mv	a4,s5
    80002468:	bfd9                	j	8000243e <wait+0xba>
    if(!havekids || p->killed){
    8000246a:	c701                	beqz	a4,80002472 <wait+0xee>
    8000246c:	02892783          	lw	a5,40(s2)
    80002470:	c79d                	beqz	a5,8000249e <wait+0x11a>
      release(&wait_lock);
    80002472:	0000f517          	auipc	a0,0xf
    80002476:	e6650513          	addi	a0,a0,-410 # 800112d8 <wait_lock>
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	81e080e7          	jalr	-2018(ra) # 80000c98 <release>
      return -1;
    80002482:	59fd                	li	s3,-1
}
    80002484:	854e                	mv	a0,s3
    80002486:	60a6                	ld	ra,72(sp)
    80002488:	6406                	ld	s0,64(sp)
    8000248a:	74e2                	ld	s1,56(sp)
    8000248c:	7942                	ld	s2,48(sp)
    8000248e:	79a2                	ld	s3,40(sp)
    80002490:	7a02                	ld	s4,32(sp)
    80002492:	6ae2                	ld	s5,24(sp)
    80002494:	6b42                	ld	s6,16(sp)
    80002496:	6ba2                	ld	s7,8(sp)
    80002498:	6c02                	ld	s8,0(sp)
    8000249a:	6161                	addi	sp,sp,80
    8000249c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249e:	85e2                	mv	a1,s8
    800024a0:	854a                	mv	a0,s2
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	e72080e7          	jalr	-398(ra) # 80002314 <sleep>
    havekids = 0;
    800024aa:	b715                	j	800023ce <wait+0x4a>

00000000800024ac <wakeup>:
{
    800024ac:	7139                	addi	sp,sp,-64
    800024ae:	fc06                	sd	ra,56(sp)
    800024b0:	f822                	sd	s0,48(sp)
    800024b2:	f426                	sd	s1,40(sp)
    800024b4:	f04a                	sd	s2,32(sp)
    800024b6:	ec4e                	sd	s3,24(sp)
    800024b8:	e852                	sd	s4,16(sp)
    800024ba:	e456                	sd	s5,8(sp)
    800024bc:	e05a                	sd	s6,0(sp)
    800024be:	0080                	addi	s0,sp,64
    800024c0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c2:	0000f497          	auipc	s1,0xf
    800024c6:	22e48493          	addi	s1,s1,558 # 800116f0 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    800024ca:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024cc:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    800024ce:	00007a97          	auipc	s5,0x7
    800024d2:	b8aa8a93          	addi	s5,s5,-1142 # 80009058 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024d6:	00015917          	auipc	s2,0x15
    800024da:	61a90913          	addi	s2,s2,1562 # 80017af0 <tickslock>
    800024de:	a811                	j	800024f2 <wakeup+0x46>
      release(&p->lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	7b6080e7          	jalr	1974(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ea:	19048493          	addi	s1,s1,400
    800024ee:	03248f63          	beq	s1,s2,8000252c <wakeup+0x80>
    if(p != myproc()){
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	4ce080e7          	jalr	1230(ra) # 800019c0 <myproc>
    800024fa:	fea488e3          	beq	s1,a0,800024ea <wakeup+0x3e>
      acquire(&p->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	6e4080e7          	jalr	1764(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002508:	4c9c                	lw	a5,24(s1)
    8000250a:	fd379be3          	bne	a5,s3,800024e0 <wakeup+0x34>
    8000250e:	709c                	ld	a5,32(s1)
    80002510:	fd4798e3          	bne	a5,s4,800024e0 <wakeup+0x34>
        update_process_timing_in_state(p, p->state);
    80002514:	85ce                	mv	a1,s3
    80002516:	8526                	mv	a0,s1
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	c50080e7          	jalr	-944(ra) # 80002168 <update_process_timing_in_state>
        p->state = RUNNABLE;
    80002520:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002524:	000ae783          	lwu	a5,0(s5)
    80002528:	fc9c                	sd	a5,56(s1)
    8000252a:	bf5d                	j	800024e0 <wakeup+0x34>
}
    8000252c:	70e2                	ld	ra,56(sp)
    8000252e:	7442                	ld	s0,48(sp)
    80002530:	74a2                	ld	s1,40(sp)
    80002532:	7902                	ld	s2,32(sp)
    80002534:	69e2                	ld	s3,24(sp)
    80002536:	6a42                	ld	s4,16(sp)
    80002538:	6aa2                	ld	s5,8(sp)
    8000253a:	6b02                	ld	s6,0(sp)
    8000253c:	6121                	addi	sp,sp,64
    8000253e:	8082                	ret

0000000080002540 <reparent>:
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	e052                	sd	s4,0(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002552:	0000f497          	auipc	s1,0xf
    80002556:	19e48493          	addi	s1,s1,414 # 800116f0 <proc>
      pp->parent = initproc;
    8000255a:	00007a17          	auipc	s4,0x7
    8000255e:	af6a0a13          	addi	s4,s4,-1290 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002562:	00015997          	auipc	s3,0x15
    80002566:	58e98993          	addi	s3,s3,1422 # 80017af0 <tickslock>
    8000256a:	a029                	j	80002574 <reparent+0x34>
    8000256c:	19048493          	addi	s1,s1,400
    80002570:	01348d63          	beq	s1,s3,8000258a <reparent+0x4a>
    if(pp->parent == p){
    80002574:	70bc                	ld	a5,96(s1)
    80002576:	ff279be3          	bne	a5,s2,8000256c <reparent+0x2c>
      pp->parent = initproc;
    8000257a:	000a3503          	ld	a0,0(s4)
    8000257e:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002580:	00000097          	auipc	ra,0x0
    80002584:	f2c080e7          	jalr	-212(ra) # 800024ac <wakeup>
    80002588:	b7d5                	j	8000256c <reparent+0x2c>
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret

000000008000259a <exit>:
{
    8000259a:	7179                	addi	sp,sp,-48
    8000259c:	f406                	sd	ra,40(sp)
    8000259e:	f022                	sd	s0,32(sp)
    800025a0:	ec26                	sd	s1,24(sp)
    800025a2:	e84a                	sd	s2,16(sp)
    800025a4:	e44e                	sd	s3,8(sp)
    800025a6:	e052                	sd	s4,0(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	414080e7          	jalr	1044(ra) # 800019c0 <myproc>
    800025b4:	892a                	mv	s2,a0
  if(p == initproc)
    800025b6:	00007797          	auipc	a5,0x7
    800025ba:	a9a7b783          	ld	a5,-1382(a5) # 80009050 <initproc>
    800025be:	0f850493          	addi	s1,a0,248
    800025c2:	17850993          	addi	s3,a0,376
    800025c6:	02a79363          	bne	a5,a0,800025ec <exit+0x52>
    panic("init exiting");
    800025ca:	00006517          	auipc	a0,0x6
    800025ce:	cae50513          	addi	a0,a0,-850 # 80008278 <digits+0x238>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>
      fileclose(f);
    800025da:	00002097          	auipc	ra,0x2
    800025de:	198080e7          	jalr	408(ra) # 80004772 <fileclose>
      p->ofile[fd] = 0;
    800025e2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025e6:	04a1                	addi	s1,s1,8
    800025e8:	01348563          	beq	s1,s3,800025f2 <exit+0x58>
    if(p->ofile[fd]){
    800025ec:	6088                	ld	a0,0(s1)
    800025ee:	f575                	bnez	a0,800025da <exit+0x40>
    800025f0:	bfdd                	j	800025e6 <exit+0x4c>
  begin_op();
    800025f2:	00002097          	auipc	ra,0x2
    800025f6:	cb4080e7          	jalr	-844(ra) # 800042a6 <begin_op>
  iput(p->cwd);
    800025fa:	17893503          	ld	a0,376(s2)
    800025fe:	00001097          	auipc	ra,0x1
    80002602:	490080e7          	jalr	1168(ra) # 80003a8e <iput>
  end_op();
    80002606:	00002097          	auipc	ra,0x2
    8000260a:	d20080e7          	jalr	-736(ra) # 80004326 <end_op>
  p->cwd = 0;
    8000260e:	16093c23          	sd	zero,376(s2)
  acquire(&wait_lock);
    80002612:	0000f997          	auipc	s3,0xf
    80002616:	cae98993          	addi	s3,s3,-850 # 800112c0 <pid_lock>
    8000261a:	0000f497          	auipc	s1,0xf
    8000261e:	cbe48493          	addi	s1,s1,-834 # 800112d8 <wait_lock>
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	5c0080e7          	jalr	1472(ra) # 80000be4 <acquire>
  reparent(p);
    8000262c:	854a                	mv	a0,s2
    8000262e:	00000097          	auipc	ra,0x0
    80002632:	f12080e7          	jalr	-238(ra) # 80002540 <reparent>
  wakeup(p->parent);
    80002636:	06093503          	ld	a0,96(s2)
    8000263a:	00000097          	auipc	ra,0x0
    8000263e:	e72080e7          	jalr	-398(ra) # 800024ac <wakeup>
  acquire(&p->lock);
    80002642:	854a                	mv	a0,s2
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	5a0080e7          	jalr	1440(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000264c:	03492623          	sw	s4,44(s2)
  update_process_timing_in_state(p, p->state);
    80002650:	01892583          	lw	a1,24(s2)
    80002654:	854a                	mv	a0,s2
    80002656:	00000097          	auipc	ra,0x0
    8000265a:	b12080e7          	jalr	-1262(ra) # 80002168 <update_process_timing_in_state>
  p->state = ZOMBIE;
    8000265e:	4795                	li	a5,5
    80002660:	00f92c23          	sw	a5,24(s2)
  acquire(&pid_lock);
    80002664:	854e                	mv	a0,s3
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	57e080e7          	jalr	1406(ra) # 80000be4 <acquire>
  running_processes_mean = ( (running_processes_mean * num_of_processes) + p->running_time) / (num_of_processes + 1);
    8000266e:	00007517          	auipc	a0,0x7
    80002672:	9da50513          	addi	a0,a0,-1574 # 80009048 <num_of_processes>
    80002676:	4110                	lw	a2,0(a0)
    80002678:	05892583          	lw	a1,88(s2)
    8000267c:	0016069b          	addiw	a3,a2,1
    80002680:	00007797          	auipc	a5,0x7
    80002684:	9b078793          	addi	a5,a5,-1616 # 80009030 <running_processes_mean>
    80002688:	4398                	lw	a4,0(a5)
    8000268a:	02c7073b          	mulw	a4,a4,a2
    8000268e:	9f2d                	addw	a4,a4,a1
    80002690:	02d7573b          	divuw	a4,a4,a3
    80002694:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ( (runnable_processes_mean * num_of_processes) + p->runnable_time) / (num_of_processes + 1);
    80002696:	00007797          	auipc	a5,0x7
    8000269a:	99e78793          	addi	a5,a5,-1634 # 80009034 <runnable_processes_mean>
    8000269e:	4398                	lw	a4,0(a5)
    800026a0:	02c7073b          	mulw	a4,a4,a2
    800026a4:	05492803          	lw	a6,84(s2)
    800026a8:	0107073b          	addw	a4,a4,a6
    800026ac:	02d7573b          	divuw	a4,a4,a3
    800026b0:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ( (sleeping_processes_mean * num_of_processes) + p->sleeping_time) / (num_of_processes + 1);
    800026b2:	00007717          	auipc	a4,0x7
    800026b6:	98670713          	addi	a4,a4,-1658 # 80009038 <sleeping_processes_mean>
    800026ba:	431c                	lw	a5,0(a4)
    800026bc:	02c787bb          	mulw	a5,a5,a2
    800026c0:	05092603          	lw	a2,80(s2)
    800026c4:	9fb1                	addw	a5,a5,a2
    800026c6:	02d7d7bb          	divuw	a5,a5,a3
    800026ca:	c31c                	sw	a5,0(a4)
  num_of_processes++;
    800026cc:	c114                	sw	a3,0(a0)
  program_time = program_time + p->running_time;
    800026ce:	00007717          	auipc	a4,0x7
    800026d2:	97670713          	addi	a4,a4,-1674 # 80009044 <program_time>
    800026d6:	431c                	lw	a5,0(a4)
    800026d8:	9fad                	addw	a5,a5,a1
    800026da:	c31c                	sw	a5,0(a4)
  cpu_utilization = program_time / (ticks - start_time);
    800026dc:	00007717          	auipc	a4,0x7
    800026e0:	97c72703          	lw	a4,-1668(a4) # 80009058 <ticks>
    800026e4:	00007697          	auipc	a3,0x7
    800026e8:	9586a683          	lw	a3,-1704(a3) # 8000903c <start_time>
    800026ec:	9f15                	subw	a4,a4,a3
    800026ee:	02e7d7bb          	divuw	a5,a5,a4
    800026f2:	00007717          	auipc	a4,0x7
    800026f6:	94f72723          	sw	a5,-1714(a4) # 80009040 <cpu_utilization>
  release(&pid_lock);
    800026fa:	854e                	mv	a0,s3
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	59c080e7          	jalr	1436(ra) # 80000c98 <release>
  release(&wait_lock);
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	592080e7          	jalr	1426(ra) # 80000c98 <release>
  sched();
    8000270e:	00000097          	auipc	ra,0x0
    80002712:	82a080e7          	jalr	-2006(ra) # 80001f38 <sched>
  panic("zombie exit");
    80002716:	00006517          	auipc	a0,0x6
    8000271a:	b7250513          	addi	a0,a0,-1166 # 80008288 <digits+0x248>
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>

0000000080002726 <kill>:
{
    80002726:	7179                	addi	sp,sp,-48
    80002728:	f406                	sd	ra,40(sp)
    8000272a:	f022                	sd	s0,32(sp)
    8000272c:	ec26                	sd	s1,24(sp)
    8000272e:	e84a                	sd	s2,16(sp)
    80002730:	e44e                	sd	s3,8(sp)
    80002732:	1800                	addi	s0,sp,48
    80002734:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002736:	0000f497          	auipc	s1,0xf
    8000273a:	fba48493          	addi	s1,s1,-70 # 800116f0 <proc>
    8000273e:	00015997          	auipc	s3,0x15
    80002742:	3b298993          	addi	s3,s3,946 # 80017af0 <tickslock>
    acquire(&p->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	49c080e7          	jalr	1180(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002750:	589c                	lw	a5,48(s1)
    80002752:	01278d63          	beq	a5,s2,8000276c <kill+0x46>
    release(&p->lock);
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	540080e7          	jalr	1344(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002760:	19048493          	addi	s1,s1,400
    80002764:	ff3491e3          	bne	s1,s3,80002746 <kill+0x20>
  return -1;
    80002768:	557d                	li	a0,-1
    8000276a:	a829                	j	80002784 <kill+0x5e>
      p->killed = 1;
    8000276c:	4785                	li	a5,1
    8000276e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002770:	4c98                	lw	a4,24(s1)
    80002772:	4789                	li	a5,2
    80002774:	00f70f63          	beq	a4,a5,80002792 <kill+0x6c>
      release(&p->lock);
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	51e080e7          	jalr	1310(ra) # 80000c98 <release>
      return 0;
    80002782:	4501                	li	a0,0
}
    80002784:	70a2                	ld	ra,40(sp)
    80002786:	7402                	ld	s0,32(sp)
    80002788:	64e2                	ld	s1,24(sp)
    8000278a:	6942                	ld	s2,16(sp)
    8000278c:	69a2                	ld	s3,8(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret
        update_process_timing_in_state(p, p->state);
    80002792:	4589                	li	a1,2
    80002794:	8526                	mv	a0,s1
    80002796:	00000097          	auipc	ra,0x0
    8000279a:	9d2080e7          	jalr	-1582(ra) # 80002168 <update_process_timing_in_state>
        p->state = RUNNABLE;
    8000279e:	478d                	li	a5,3
    800027a0:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    800027a2:	00007797          	auipc	a5,0x7
    800027a6:	8b67e783          	lwu	a5,-1866(a5) # 80009058 <ticks>
    800027aa:	fc9c                	sd	a5,56(s1)
    800027ac:	b7f1                	j	80002778 <kill+0x52>

00000000800027ae <kill_system>:
int kill_system(void){	//maybe check we don't kill ourselves first
    800027ae:	7139                	addi	sp,sp,-64
    800027b0:	fc06                	sd	ra,56(sp)
    800027b2:	f822                	sd	s0,48(sp)
    800027b4:	f426                	sd	s1,40(sp)
    800027b6:	f04a                	sd	s2,32(sp)
    800027b8:	ec4e                	sd	s3,24(sp)
    800027ba:	e852                	sd	s4,16(sp)
    800027bc:	e456                	sd	s5,8(sp)
    800027be:	0080                	addi	s0,sp,64
  struct proc *cur = myproc();
    800027c0:	fffff097          	auipc	ra,0xfffff
    800027c4:	200080e7          	jalr	512(ra) # 800019c0 <myproc>
    800027c8:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    800027ca:	0000f497          	auipc	s1,0xf
    800027ce:	f2648493          	addi	s1,s1,-218 # 800116f0 <proc>
    if(p->pid != cur->pid && p->pid != INIT_PROC_PID && p->pid != SHELL_PROC_PID){
    800027d2:	4a05                	li	s4,1
      if(kill(p->pid) == -1){
    800027d4:	5afd                	li	s5,-1
  for(p = proc; p < &proc[NPROC]; p++){
    800027d6:	00015997          	auipc	s3,0x15
    800027da:	31a98993          	addi	s3,s3,794 # 80017af0 <tickslock>
    800027de:	a029                	j	800027e8 <kill_system+0x3a>
    800027e0:	19048493          	addi	s1,s1,400
    800027e4:	03348263          	beq	s1,s3,80002808 <kill_system+0x5a>
    if(p->pid != cur->pid && p->pid != INIT_PROC_PID && p->pid != SHELL_PROC_PID){
    800027e8:	5888                	lw	a0,48(s1)
    800027ea:	03092783          	lw	a5,48(s2)
    800027ee:	fea789e3          	beq	a5,a0,800027e0 <kill_system+0x32>
    800027f2:	fff5079b          	addiw	a5,a0,-1
    800027f6:	fefa75e3          	bgeu	s4,a5,800027e0 <kill_system+0x32>
      if(kill(p->pid) == -1){
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	f2c080e7          	jalr	-212(ra) # 80002726 <kill>
    80002802:	fd551fe3          	bne	a0,s5,800027e0 <kill_system+0x32>
    80002806:	a039                	j	80002814 <kill_system+0x66>
	return kill(cur->pid);
    80002808:	03092503          	lw	a0,48(s2)
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	f1a080e7          	jalr	-230(ra) # 80002726 <kill>
}
    80002814:	70e2                	ld	ra,56(sp)
    80002816:	7442                	ld	s0,48(sp)
    80002818:	74a2                	ld	s1,40(sp)
    8000281a:	7902                	ld	s2,32(sp)
    8000281c:	69e2                	ld	s3,24(sp)
    8000281e:	6a42                	ld	s4,16(sp)
    80002820:	6aa2                	ld	s5,8(sp)
    80002822:	6121                	addi	sp,sp,64
    80002824:	8082                	ret

0000000080002826 <swtch>:
    80002826:	00153023          	sd	ra,0(a0)
    8000282a:	00253423          	sd	sp,8(a0)
    8000282e:	e900                	sd	s0,16(a0)
    80002830:	ed04                	sd	s1,24(a0)
    80002832:	03253023          	sd	s2,32(a0)
    80002836:	03353423          	sd	s3,40(a0)
    8000283a:	03453823          	sd	s4,48(a0)
    8000283e:	03553c23          	sd	s5,56(a0)
    80002842:	05653023          	sd	s6,64(a0)
    80002846:	05753423          	sd	s7,72(a0)
    8000284a:	05853823          	sd	s8,80(a0)
    8000284e:	05953c23          	sd	s9,88(a0)
    80002852:	07a53023          	sd	s10,96(a0)
    80002856:	07b53423          	sd	s11,104(a0)
    8000285a:	0005b083          	ld	ra,0(a1)
    8000285e:	0085b103          	ld	sp,8(a1)
    80002862:	6980                	ld	s0,16(a1)
    80002864:	6d84                	ld	s1,24(a1)
    80002866:	0205b903          	ld	s2,32(a1)
    8000286a:	0285b983          	ld	s3,40(a1)
    8000286e:	0305ba03          	ld	s4,48(a1)
    80002872:	0385ba83          	ld	s5,56(a1)
    80002876:	0405bb03          	ld	s6,64(a1)
    8000287a:	0485bb83          	ld	s7,72(a1)
    8000287e:	0505bc03          	ld	s8,80(a1)
    80002882:	0585bc83          	ld	s9,88(a1)
    80002886:	0605bd03          	ld	s10,96(a1)
    8000288a:	0685bd83          	ld	s11,104(a1)
    8000288e:	8082                	ret

0000000080002890 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002890:	1141                	addi	sp,sp,-16
    80002892:	e406                	sd	ra,8(sp)
    80002894:	e022                	sd	s0,0(sp)
    80002896:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002898:	00006597          	auipc	a1,0x6
    8000289c:	a5858593          	addi	a1,a1,-1448 # 800082f0 <states.1732+0x30>
    800028a0:	00015517          	auipc	a0,0x15
    800028a4:	25050513          	addi	a0,a0,592 # 80017af0 <tickslock>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	2ac080e7          	jalr	684(ra) # 80000b54 <initlock>
}
    800028b0:	60a2                	ld	ra,8(sp)
    800028b2:	6402                	ld	s0,0(sp)
    800028b4:	0141                	addi	sp,sp,16
    800028b6:	8082                	ret

00000000800028b8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028b8:	1141                	addi	sp,sp,-16
    800028ba:	e422                	sd	s0,8(sp)
    800028bc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028be:	00003797          	auipc	a5,0x3
    800028c2:	4d278793          	addi	a5,a5,1234 # 80005d90 <kernelvec>
    800028c6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028ca:	6422                	ld	s0,8(sp)
    800028cc:	0141                	addi	sp,sp,16
    800028ce:	8082                	ret

00000000800028d0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028d0:	1141                	addi	sp,sp,-16
    800028d2:	e406                	sd	ra,8(sp)
    800028d4:	e022                	sd	s0,0(sp)
    800028d6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028d8:	fffff097          	auipc	ra,0xfffff
    800028dc:	0e8080e7          	jalr	232(ra) # 800019c0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028ea:	00004617          	auipc	a2,0x4
    800028ee:	71660613          	addi	a2,a2,1814 # 80007000 <_trampoline>
    800028f2:	00004697          	auipc	a3,0x4
    800028f6:	70e68693          	addi	a3,a3,1806 # 80007000 <_trampoline>
    800028fa:	8e91                	sub	a3,a3,a2
    800028fc:	040007b7          	lui	a5,0x4000
    80002900:	17fd                	addi	a5,a5,-1
    80002902:	07b2                	slli	a5,a5,0xc
    80002904:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002906:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000290a:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000290c:	180026f3          	csrr	a3,satp
    80002910:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002912:	6158                	ld	a4,128(a0)
    80002914:	7534                	ld	a3,104(a0)
    80002916:	6585                	lui	a1,0x1
    80002918:	96ae                	add	a3,a3,a1
    8000291a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000291c:	6158                	ld	a4,128(a0)
    8000291e:	00000697          	auipc	a3,0x0
    80002922:	13868693          	addi	a3,a3,312 # 80002a56 <usertrap>
    80002926:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002928:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000292a:	8692                	mv	a3,tp
    8000292c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002932:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002936:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000293a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000293e:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002940:	6f18                	ld	a4,24(a4)
    80002942:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002946:	7d2c                	ld	a1,120(a0)
    80002948:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000294a:	00004717          	auipc	a4,0x4
    8000294e:	74670713          	addi	a4,a4,1862 # 80007090 <userret>
    80002952:	8f11                	sub	a4,a4,a2
    80002954:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002956:	577d                	li	a4,-1
    80002958:	177e                	slli	a4,a4,0x3f
    8000295a:	8dd9                	or	a1,a1,a4
    8000295c:	02000537          	lui	a0,0x2000
    80002960:	157d                	addi	a0,a0,-1
    80002962:	0536                	slli	a0,a0,0xd
    80002964:	9782                	jalr	a5
}
    80002966:	60a2                	ld	ra,8(sp)
    80002968:	6402                	ld	s0,0(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000296e:	1101                	addi	sp,sp,-32
    80002970:	ec06                	sd	ra,24(sp)
    80002972:	e822                	sd	s0,16(sp)
    80002974:	e426                	sd	s1,8(sp)
    80002976:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002978:	00015497          	auipc	s1,0x15
    8000297c:	17848493          	addi	s1,s1,376 # 80017af0 <tickslock>
    80002980:	8526                	mv	a0,s1
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	262080e7          	jalr	610(ra) # 80000be4 <acquire>
  ticks++;
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	6ce50513          	addi	a0,a0,1742 # 80009058 <ticks>
    80002992:	411c                	lw	a5,0(a0)
    80002994:	2785                	addiw	a5,a5,1
    80002996:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	b14080e7          	jalr	-1260(ra) # 800024ac <wakeup>
  release(&tickslock);
    800029a0:	8526                	mv	a0,s1
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	2f6080e7          	jalr	758(ra) # 80000c98 <release>
}
    800029aa:	60e2                	ld	ra,24(sp)
    800029ac:	6442                	ld	s0,16(sp)
    800029ae:	64a2                	ld	s1,8(sp)
    800029b0:	6105                	addi	sp,sp,32
    800029b2:	8082                	ret

00000000800029b4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029c2:	00074d63          	bltz	a4,800029dc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029c6:	57fd                	li	a5,-1
    800029c8:	17fe                	slli	a5,a5,0x3f
    800029ca:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029cc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029ce:	06f70363          	beq	a4,a5,80002a34 <devintr+0x80>
  }
}
    800029d2:	60e2                	ld	ra,24(sp)
    800029d4:	6442                	ld	s0,16(sp)
    800029d6:	64a2                	ld	s1,8(sp)
    800029d8:	6105                	addi	sp,sp,32
    800029da:	8082                	ret
     (scause & 0xff) == 9){
    800029dc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029e0:	46a5                	li	a3,9
    800029e2:	fed792e3          	bne	a5,a3,800029c6 <devintr+0x12>
    int irq = plic_claim();
    800029e6:	00003097          	auipc	ra,0x3
    800029ea:	4b2080e7          	jalr	1202(ra) # 80005e98 <plic_claim>
    800029ee:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029f0:	47a9                	li	a5,10
    800029f2:	02f50763          	beq	a0,a5,80002a20 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029f6:	4785                	li	a5,1
    800029f8:	02f50963          	beq	a0,a5,80002a2a <devintr+0x76>
    return 1;
    800029fc:	4505                	li	a0,1
    } else if(irq){
    800029fe:	d8f1                	beqz	s1,800029d2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a00:	85a6                	mv	a1,s1
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	8f650513          	addi	a0,a0,-1802 # 800082f8 <states.1732+0x38>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a12:	8526                	mv	a0,s1
    80002a14:	00003097          	auipc	ra,0x3
    80002a18:	4a8080e7          	jalr	1192(ra) # 80005ebc <plic_complete>
    return 1;
    80002a1c:	4505                	li	a0,1
    80002a1e:	bf55                	j	800029d2 <devintr+0x1e>
      uartintr();
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	f88080e7          	jalr	-120(ra) # 800009a8 <uartintr>
    80002a28:	b7ed                	j	80002a12 <devintr+0x5e>
      virtio_disk_intr();
    80002a2a:	00004097          	auipc	ra,0x4
    80002a2e:	972080e7          	jalr	-1678(ra) # 8000639c <virtio_disk_intr>
    80002a32:	b7c5                	j	80002a12 <devintr+0x5e>
    if(cpuid() == 0){
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	f60080e7          	jalr	-160(ra) # 80001994 <cpuid>
    80002a3c:	c901                	beqz	a0,80002a4c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a3e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a44:	14479073          	csrw	sip,a5
    return 2;
    80002a48:	4509                	li	a0,2
    80002a4a:	b761                	j	800029d2 <devintr+0x1e>
      clockintr();
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	f22080e7          	jalr	-222(ra) # 8000296e <clockintr>
    80002a54:	b7ed                	j	80002a3e <devintr+0x8a>

0000000080002a56 <usertrap>:
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	e04a                	sd	s2,0(sp)
    80002a60:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a62:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a66:	1007f793          	andi	a5,a5,256
    80002a6a:	e3ad                	bnez	a5,80002acc <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a6c:	00003797          	auipc	a5,0x3
    80002a70:	32478793          	addi	a5,a5,804 # 80005d90 <kernelvec>
    80002a74:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f48080e7          	jalr	-184(ra) # 800019c0 <myproc>
    80002a80:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a82:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a84:	14102773          	csrr	a4,sepc
    80002a88:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a8e:	47a1                	li	a5,8
    80002a90:	04f71c63          	bne	a4,a5,80002ae8 <usertrap+0x92>
    if(p->killed)
    80002a94:	551c                	lw	a5,40(a0)
    80002a96:	e3b9                	bnez	a5,80002adc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a98:	60d8                	ld	a4,128(s1)
    80002a9a:	6f1c                	ld	a5,24(a4)
    80002a9c:	0791                	addi	a5,a5,4
    80002a9e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aa4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa8:	10079073          	csrw	sstatus,a5
    syscall();
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	2e0080e7          	jalr	736(ra) # 80002d8c <syscall>
  if(p->killed)
    80002ab4:	549c                	lw	a5,40(s1)
    80002ab6:	ebc1                	bnez	a5,80002b46 <usertrap+0xf0>
  usertrapret();
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	e18080e7          	jalr	-488(ra) # 800028d0 <usertrapret>
}
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6902                	ld	s2,0(sp)
    80002ac8:	6105                	addi	sp,sp,32
    80002aca:	8082                	ret
    panic("usertrap: not from user mode");
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	84c50513          	addi	a0,a0,-1972 # 80008318 <states.1732+0x58>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	a6a080e7          	jalr	-1430(ra) # 8000053e <panic>
      exit(-1);
    80002adc:	557d                	li	a0,-1
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	abc080e7          	jalr	-1348(ra) # 8000259a <exit>
    80002ae6:	bf4d                	j	80002a98 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	ecc080e7          	jalr	-308(ra) # 800029b4 <devintr>
    80002af0:	892a                	mv	s2,a0
    80002af2:	c501                	beqz	a0,80002afa <usertrap+0xa4>
  if(p->killed)
    80002af4:	549c                	lw	a5,40(s1)
    80002af6:	c3a1                	beqz	a5,80002b36 <usertrap+0xe0>
    80002af8:	a815                	j	80002b2c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002afe:	5890                	lw	a2,48(s1)
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	83850513          	addi	a0,a0,-1992 # 80008338 <states.1732+0x78>
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a80080e7          	jalr	-1408(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b14:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	85050513          	addi	a0,a0,-1968 # 80008368 <states.1732+0xa8>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a68080e7          	jalr	-1432(ra) # 80000588 <printf>
    p->killed = 1;
    80002b28:	4785                	li	a5,1
    80002b2a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b2c:	557d                	li	a0,-1
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	a6c080e7          	jalr	-1428(ra) # 8000259a <exit>
  if(which_dev == 2)
    80002b36:	4789                	li	a5,2
    80002b38:	f8f910e3          	bne	s2,a5,80002ab8 <usertrap+0x62>
    yield();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	744080e7          	jalr	1860(ra) # 80002280 <yield>
    80002b44:	bf95                	j	80002ab8 <usertrap+0x62>
  int which_dev = 0;
    80002b46:	4901                	li	s2,0
    80002b48:	b7d5                	j	80002b2c <usertrap+0xd6>

0000000080002b4a <kerneltrap>:
{
    80002b4a:	7179                	addi	sp,sp,-48
    80002b4c:	f406                	sd	ra,40(sp)
    80002b4e:	f022                	sd	s0,32(sp)
    80002b50:	ec26                	sd	s1,24(sp)
    80002b52:	e84a                	sd	s2,16(sp)
    80002b54:	e44e                	sd	s3,8(sp)
    80002b56:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b60:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b64:	1004f793          	andi	a5,s1,256
    80002b68:	cb85                	beqz	a5,80002b98 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b6e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b70:	ef85                	bnez	a5,80002ba8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	e42080e7          	jalr	-446(ra) # 800029b4 <devintr>
    80002b7a:	cd1d                	beqz	a0,80002bb8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b7c:	4789                	li	a5,2
    80002b7e:	06f50a63          	beq	a0,a5,80002bf2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b82:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b86:	10049073          	csrw	sstatus,s1
}
    80002b8a:	70a2                	ld	ra,40(sp)
    80002b8c:	7402                	ld	s0,32(sp)
    80002b8e:	64e2                	ld	s1,24(sp)
    80002b90:	6942                	ld	s2,16(sp)
    80002b92:	69a2                	ld	s3,8(sp)
    80002b94:	6145                	addi	sp,sp,48
    80002b96:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b98:	00005517          	auipc	a0,0x5
    80002b9c:	7f050513          	addi	a0,a0,2032 # 80008388 <states.1732+0xc8>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	99e080e7          	jalr	-1634(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	80850513          	addi	a0,a0,-2040 # 800083b0 <states.1732+0xf0>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002bb8:	85ce                	mv	a1,s3
    80002bba:	00006517          	auipc	a0,0x6
    80002bbe:	81650513          	addi	a0,a0,-2026 # 800083d0 <states.1732+0x110>
    80002bc2:	ffffe097          	auipc	ra,0xffffe
    80002bc6:	9c6080e7          	jalr	-1594(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bce:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bd2:	00006517          	auipc	a0,0x6
    80002bd6:	80e50513          	addi	a0,a0,-2034 # 800083e0 <states.1732+0x120>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	9ae080e7          	jalr	-1618(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002be2:	00006517          	auipc	a0,0x6
    80002be6:	81650513          	addi	a0,a0,-2026 # 800083f8 <states.1732+0x138>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	954080e7          	jalr	-1708(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	dce080e7          	jalr	-562(ra) # 800019c0 <myproc>
    80002bfa:	d541                	beqz	a0,80002b82 <kerneltrap+0x38>
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	dc4080e7          	jalr	-572(ra) # 800019c0 <myproc>
    80002c04:	4d18                	lw	a4,24(a0)
    80002c06:	4791                	li	a5,4
    80002c08:	f6f71de3          	bne	a4,a5,80002b82 <kerneltrap+0x38>
    yield();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	674080e7          	jalr	1652(ra) # 80002280 <yield>
    80002c14:	b7bd                	j	80002b82 <kerneltrap+0x38>

0000000080002c16 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	e426                	sd	s1,8(sp)
    80002c1e:	1000                	addi	s0,sp,32
    80002c20:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	d9e080e7          	jalr	-610(ra) # 800019c0 <myproc>
  switch (n) {
    80002c2a:	4795                	li	a5,5
    80002c2c:	0497e163          	bltu	a5,s1,80002c6e <argraw+0x58>
    80002c30:	048a                	slli	s1,s1,0x2
    80002c32:	00005717          	auipc	a4,0x5
    80002c36:	7fe70713          	addi	a4,a4,2046 # 80008430 <states.1732+0x170>
    80002c3a:	94ba                	add	s1,s1,a4
    80002c3c:	409c                	lw	a5,0(s1)
    80002c3e:	97ba                	add	a5,a5,a4
    80002c40:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c42:	615c                	ld	a5,128(a0)
    80002c44:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	64a2                	ld	s1,8(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret
    return p->trapframe->a1;
    80002c50:	615c                	ld	a5,128(a0)
    80002c52:	7fa8                	ld	a0,120(a5)
    80002c54:	bfcd                	j	80002c46 <argraw+0x30>
    return p->trapframe->a2;
    80002c56:	615c                	ld	a5,128(a0)
    80002c58:	63c8                	ld	a0,128(a5)
    80002c5a:	b7f5                	j	80002c46 <argraw+0x30>
    return p->trapframe->a3;
    80002c5c:	615c                	ld	a5,128(a0)
    80002c5e:	67c8                	ld	a0,136(a5)
    80002c60:	b7dd                	j	80002c46 <argraw+0x30>
    return p->trapframe->a4;
    80002c62:	615c                	ld	a5,128(a0)
    80002c64:	6bc8                	ld	a0,144(a5)
    80002c66:	b7c5                	j	80002c46 <argraw+0x30>
    return p->trapframe->a5;
    80002c68:	615c                	ld	a5,128(a0)
    80002c6a:	6fc8                	ld	a0,152(a5)
    80002c6c:	bfe9                	j	80002c46 <argraw+0x30>
  panic("argraw");
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	79a50513          	addi	a0,a0,1946 # 80008408 <states.1732+0x148>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>

0000000080002c7e <fetchaddr>:
{
    80002c7e:	1101                	addi	sp,sp,-32
    80002c80:	ec06                	sd	ra,24(sp)
    80002c82:	e822                	sd	s0,16(sp)
    80002c84:	e426                	sd	s1,8(sp)
    80002c86:	e04a                	sd	s2,0(sp)
    80002c88:	1000                	addi	s0,sp,32
    80002c8a:	84aa                	mv	s1,a0
    80002c8c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	d32080e7          	jalr	-718(ra) # 800019c0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c96:	793c                	ld	a5,112(a0)
    80002c98:	02f4f863          	bgeu	s1,a5,80002cc8 <fetchaddr+0x4a>
    80002c9c:	00848713          	addi	a4,s1,8
    80002ca0:	02e7e663          	bltu	a5,a4,80002ccc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ca4:	46a1                	li	a3,8
    80002ca6:	8626                	mv	a2,s1
    80002ca8:	85ca                	mv	a1,s2
    80002caa:	7d28                	ld	a0,120(a0)
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	a52080e7          	jalr	-1454(ra) # 800016fe <copyin>
    80002cb4:	00a03533          	snez	a0,a0
    80002cb8:	40a00533          	neg	a0,a0
}
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	64a2                	ld	s1,8(sp)
    80002cc2:	6902                	ld	s2,0(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret
    return -1;
    80002cc8:	557d                	li	a0,-1
    80002cca:	bfcd                	j	80002cbc <fetchaddr+0x3e>
    80002ccc:	557d                	li	a0,-1
    80002cce:	b7fd                	j	80002cbc <fetchaddr+0x3e>

0000000080002cd0 <fetchstr>:
{
    80002cd0:	7179                	addi	sp,sp,-48
    80002cd2:	f406                	sd	ra,40(sp)
    80002cd4:	f022                	sd	s0,32(sp)
    80002cd6:	ec26                	sd	s1,24(sp)
    80002cd8:	e84a                	sd	s2,16(sp)
    80002cda:	e44e                	sd	s3,8(sp)
    80002cdc:	1800                	addi	s0,sp,48
    80002cde:	892a                	mv	s2,a0
    80002ce0:	84ae                	mv	s1,a1
    80002ce2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	cdc080e7          	jalr	-804(ra) # 800019c0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cec:	86ce                	mv	a3,s3
    80002cee:	864a                	mv	a2,s2
    80002cf0:	85a6                	mv	a1,s1
    80002cf2:	7d28                	ld	a0,120(a0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	a96080e7          	jalr	-1386(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002cfc:	00054763          	bltz	a0,80002d0a <fetchstr+0x3a>
  return strlen(buf);
    80002d00:	8526                	mv	a0,s1
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	162080e7          	jalr	354(ra) # 80000e64 <strlen>
}
    80002d0a:	70a2                	ld	ra,40(sp)
    80002d0c:	7402                	ld	s0,32(sp)
    80002d0e:	64e2                	ld	s1,24(sp)
    80002d10:	6942                	ld	s2,16(sp)
    80002d12:	69a2                	ld	s3,8(sp)
    80002d14:	6145                	addi	sp,sp,48
    80002d16:	8082                	ret

0000000080002d18 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
    80002d22:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	ef2080e7          	jalr	-270(ra) # 80002c16 <argraw>
    80002d2c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d2e:	4501                	li	a0,0
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret

0000000080002d3a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	e426                	sd	s1,8(sp)
    80002d42:	1000                	addi	s0,sp,32
    80002d44:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	ed0080e7          	jalr	-304(ra) # 80002c16 <argraw>
    80002d4e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d50:	4501                	li	a0,0
    80002d52:	60e2                	ld	ra,24(sp)
    80002d54:	6442                	ld	s0,16(sp)
    80002d56:	64a2                	ld	s1,8(sp)
    80002d58:	6105                	addi	sp,sp,32
    80002d5a:	8082                	ret

0000000080002d5c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d5c:	1101                	addi	sp,sp,-32
    80002d5e:	ec06                	sd	ra,24(sp)
    80002d60:	e822                	sd	s0,16(sp)
    80002d62:	e426                	sd	s1,8(sp)
    80002d64:	e04a                	sd	s2,0(sp)
    80002d66:	1000                	addi	s0,sp,32
    80002d68:	84ae                	mv	s1,a1
    80002d6a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	eaa080e7          	jalr	-342(ra) # 80002c16 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d74:	864a                	mv	a2,s2
    80002d76:	85a6                	mv	a1,s1
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	f58080e7          	jalr	-168(ra) # 80002cd0 <fetchstr>
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6902                	ld	s2,0(sp)
    80002d88:	6105                	addi	sp,sp,32
    80002d8a:	8082                	ret

0000000080002d8c <syscall>:
[SYS_allk]    sys_allk	//*
};

void
syscall(void)
{
    80002d8c:	1101                	addi	sp,sp,-32
    80002d8e:	ec06                	sd	ra,24(sp)
    80002d90:	e822                	sd	s0,16(sp)
    80002d92:	e426                	sd	s1,8(sp)
    80002d94:	e04a                	sd	s2,0(sp)
    80002d96:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	c28080e7          	jalr	-984(ra) # 800019c0 <myproc>
    80002da0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002da2:	08053903          	ld	s2,128(a0)
    80002da6:	0a893783          	ld	a5,168(s2)
    80002daa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dae:	37fd                	addiw	a5,a5,-1
    80002db0:	4759                	li	a4,22
    80002db2:	00f76f63          	bltu	a4,a5,80002dd0 <syscall+0x44>
    80002db6:	00369713          	slli	a4,a3,0x3
    80002dba:	00005797          	auipc	a5,0x5
    80002dbe:	68e78793          	addi	a5,a5,1678 # 80008448 <syscalls>
    80002dc2:	97ba                	add	a5,a5,a4
    80002dc4:	639c                	ld	a5,0(a5)
    80002dc6:	c789                	beqz	a5,80002dd0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002dc8:	9782                	jalr	a5
    80002dca:	06a93823          	sd	a0,112(s2)
    80002dce:	a839                	j	80002dec <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dd0:	18048613          	addi	a2,s1,384
    80002dd4:	588c                	lw	a1,48(s1)
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	63a50513          	addi	a0,a0,1594 # 80008410 <states.1732+0x150>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	7aa080e7          	jalr	1962(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002de6:	60dc                	ld	a5,128(s1)
    80002de8:	577d                	li	a4,-1
    80002dea:	fbb8                	sd	a4,112(a5)
  }
}
    80002dec:	60e2                	ld	ra,24(sp)
    80002dee:	6442                	ld	s0,16(sp)
    80002df0:	64a2                	ld	s1,8(sp)
    80002df2:	6902                	ld	s2,0(sp)
    80002df4:	6105                	addi	sp,sp,32
    80002df6:	8082                	ret

0000000080002df8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e00:	fec40593          	addi	a1,s0,-20
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	f12080e7          	jalr	-238(ra) # 80002d18 <argint>
    return -1;
    80002e0e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e10:	00054963          	bltz	a0,80002e22 <sys_exit+0x2a>
  exit(n);
    80002e14:	fec42503          	lw	a0,-20(s0)
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	782080e7          	jalr	1922(ra) # 8000259a <exit>
  return 0;  // not reached
    80002e20:	4781                	li	a5,0
}
    80002e22:	853e                	mv	a0,a5
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	6105                	addi	sp,sp,32
    80002e2a:	8082                	ret

0000000080002e2c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e2c:	1141                	addi	sp,sp,-16
    80002e2e:	e406                	sd	ra,8(sp)
    80002e30:	e022                	sd	s0,0(sp)
    80002e32:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	b8c080e7          	jalr	-1140(ra) # 800019c0 <myproc>
}
    80002e3c:	5908                	lw	a0,48(a0)
    80002e3e:	60a2                	ld	ra,8(sp)
    80002e40:	6402                	ld	s0,0(sp)
    80002e42:	0141                	addi	sp,sp,16
    80002e44:	8082                	ret

0000000080002e46 <sys_fork>:

uint64
sys_fork(void)
{
    80002e46:	1141                	addi	sp,sp,-16
    80002e48:	e406                	sd	ra,8(sp)
    80002e4a:	e022                	sd	s0,0(sp)
    80002e4c:	0800                	addi	s0,sp,16
  return fork();
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	f8e080e7          	jalr	-114(ra) # 80001ddc <fork>
}
    80002e56:	60a2                	ld	ra,8(sp)
    80002e58:	6402                	ld	s0,0(sp)
    80002e5a:	0141                	addi	sp,sp,16
    80002e5c:	8082                	ret

0000000080002e5e <sys_wait>:

uint64
sys_wait(void)
{
    80002e5e:	1101                	addi	sp,sp,-32
    80002e60:	ec06                	sd	ra,24(sp)
    80002e62:	e822                	sd	s0,16(sp)
    80002e64:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e66:	fe840593          	addi	a1,s0,-24
    80002e6a:	4501                	li	a0,0
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	ece080e7          	jalr	-306(ra) # 80002d3a <argaddr>
    80002e74:	87aa                	mv	a5,a0
    return -1;
    80002e76:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e78:	0007c863          	bltz	a5,80002e88 <sys_wait+0x2a>
  return wait(p);
    80002e7c:	fe843503          	ld	a0,-24(s0)
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	504080e7          	jalr	1284(ra) # 80002384 <wait>
}
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	6105                	addi	sp,sp,32
    80002e8e:	8082                	ret

0000000080002e90 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e9a:	fdc40593          	addi	a1,s0,-36
    80002e9e:	4501                	li	a0,0
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	e78080e7          	jalr	-392(ra) # 80002d18 <argint>
    80002ea8:	87aa                	mv	a5,a0
    return -1;
    80002eaa:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002eac:	0207c063          	bltz	a5,80002ecc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	b10080e7          	jalr	-1264(ra) # 800019c0 <myproc>
    80002eb8:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80002eba:	fdc42503          	lw	a0,-36(s0)
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	eaa080e7          	jalr	-342(ra) # 80001d68 <growproc>
    80002ec6:	00054863          	bltz	a0,80002ed6 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002eca:	8526                	mv	a0,s1
}
    80002ecc:	70a2                	ld	ra,40(sp)
    80002ece:	7402                	ld	s0,32(sp)
    80002ed0:	64e2                	ld	s1,24(sp)
    80002ed2:	6145                	addi	sp,sp,48
    80002ed4:	8082                	ret
    return -1;
    80002ed6:	557d                	li	a0,-1
    80002ed8:	bfd5                	j	80002ecc <sys_sbrk+0x3c>

0000000080002eda <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eda:	7139                	addi	sp,sp,-64
    80002edc:	fc06                	sd	ra,56(sp)
    80002ede:	f822                	sd	s0,48(sp)
    80002ee0:	f426                	sd	s1,40(sp)
    80002ee2:	f04a                	sd	s2,32(sp)
    80002ee4:	ec4e                	sd	s3,24(sp)
    80002ee6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ee8:	fcc40593          	addi	a1,s0,-52
    80002eec:	4501                	li	a0,0
    80002eee:	00000097          	auipc	ra,0x0
    80002ef2:	e2a080e7          	jalr	-470(ra) # 80002d18 <argint>
    return -1;
    80002ef6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef8:	06054563          	bltz	a0,80002f62 <sys_sleep+0x88>
  acquire(&tickslock);
    80002efc:	00015517          	auipc	a0,0x15
    80002f00:	bf450513          	addi	a0,a0,-1036 # 80017af0 <tickslock>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	ce0080e7          	jalr	-800(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f0c:	00006917          	auipc	s2,0x6
    80002f10:	14c92903          	lw	s2,332(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    80002f14:	fcc42783          	lw	a5,-52(s0)
    80002f18:	cf85                	beqz	a5,80002f50 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f1a:	00015997          	auipc	s3,0x15
    80002f1e:	bd698993          	addi	s3,s3,-1066 # 80017af0 <tickslock>
    80002f22:	00006497          	auipc	s1,0x6
    80002f26:	13648493          	addi	s1,s1,310 # 80009058 <ticks>
    if(myproc()->killed){
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	a96080e7          	jalr	-1386(ra) # 800019c0 <myproc>
    80002f32:	551c                	lw	a5,40(a0)
    80002f34:	ef9d                	bnez	a5,80002f72 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f36:	85ce                	mv	a1,s3
    80002f38:	8526                	mv	a0,s1
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	3da080e7          	jalr	986(ra) # 80002314 <sleep>
  while(ticks - ticks0 < n){
    80002f42:	409c                	lw	a5,0(s1)
    80002f44:	412787bb          	subw	a5,a5,s2
    80002f48:	fcc42703          	lw	a4,-52(s0)
    80002f4c:	fce7efe3          	bltu	a5,a4,80002f2a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f50:	00015517          	auipc	a0,0x15
    80002f54:	ba050513          	addi	a0,a0,-1120 # 80017af0 <tickslock>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	d40080e7          	jalr	-704(ra) # 80000c98 <release>
  return 0;
    80002f60:	4781                	li	a5,0
}
    80002f62:	853e                	mv	a0,a5
    80002f64:	70e2                	ld	ra,56(sp)
    80002f66:	7442                	ld	s0,48(sp)
    80002f68:	74a2                	ld	s1,40(sp)
    80002f6a:	7902                	ld	s2,32(sp)
    80002f6c:	69e2                	ld	s3,24(sp)
    80002f6e:	6121                	addi	sp,sp,64
    80002f70:	8082                	ret
      release(&tickslock);
    80002f72:	00015517          	auipc	a0,0x15
    80002f76:	b7e50513          	addi	a0,a0,-1154 # 80017af0 <tickslock>
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	d1e080e7          	jalr	-738(ra) # 80000c98 <release>
      return -1;
    80002f82:	57fd                	li	a5,-1
    80002f84:	bff9                	j	80002f62 <sys_sleep+0x88>

0000000080002f86 <sys_kill>:

uint64
sys_kill(void)
{
    80002f86:	1101                	addi	sp,sp,-32
    80002f88:	ec06                	sd	ra,24(sp)
    80002f8a:	e822                	sd	s0,16(sp)
    80002f8c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f8e:	fec40593          	addi	a1,s0,-20
    80002f92:	4501                	li	a0,0
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	d84080e7          	jalr	-636(ra) # 80002d18 <argint>
    80002f9c:	87aa                	mv	a5,a0
    return -1;
    80002f9e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fa0:	0007c863          	bltz	a5,80002fb0 <sys_kill+0x2a>
  return kill(pid);
    80002fa4:	fec42503          	lw	a0,-20(s0)
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	77e080e7          	jalr	1918(ra) # 80002726 <kill>
}
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	6105                	addi	sp,sp,32
    80002fb6:	8082                	ret

0000000080002fb8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	e426                	sd	s1,8(sp)
    80002fc0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fc2:	00015517          	auipc	a0,0x15
    80002fc6:	b2e50513          	addi	a0,a0,-1234 # 80017af0 <tickslock>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	c1a080e7          	jalr	-998(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fd2:	00006497          	auipc	s1,0x6
    80002fd6:	0864a483          	lw	s1,134(s1) # 80009058 <ticks>
  release(&tickslock);
    80002fda:	00015517          	auipc	a0,0x15
    80002fde:	b1650513          	addi	a0,a0,-1258 # 80017af0 <tickslock>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
  return xticks;
}
    80002fea:	02049513          	slli	a0,s1,0x20
    80002fee:	9101                	srli	a0,a0,0x20
    80002ff0:	60e2                	ld	ra,24(sp)
    80002ff2:	6442                	ld	s0,16(sp)
    80002ff4:	64a2                	ld	s1,8(sp)
    80002ff6:	6105                	addi	sp,sp,32
    80002ff8:	8082                	ret

0000000080002ffa <sys_allp>:

uint64
sys_allp(void)		//*
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	1000                	addi	s0,sp,32
	int seconds;
	if(argint(0, &seconds) < 0)
    80003002:	fec40593          	addi	a1,s0,-20
    80003006:	4501                	li	a0,0
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	d10080e7          	jalr	-752(ra) # 80002d18 <argint>
    80003010:	87aa                	mv	a5,a0
		return -1;
    80003012:	557d                	li	a0,-1
	if(argint(0, &seconds) < 0)
    80003014:	0007c863          	bltz	a5,80003024 <sys_allp+0x2a>
	return pause_system(seconds);
    80003018:	fec42503          	lw	a0,-20(s0)
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	2b6080e7          	jalr	694(ra) # 800022d2 <pause_system>
}
    80003024:	60e2                	ld	ra,24(sp)
    80003026:	6442                	ld	s0,16(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret

000000008000302c <sys_allk>:

uint64
sys_allk(void)		//*
{
    8000302c:	1141                	addi	sp,sp,-16
    8000302e:	e406                	sd	ra,8(sp)
    80003030:	e022                	sd	s0,0(sp)
    80003032:	0800                	addi	s0,sp,16
	return kill_system();
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	77a080e7          	jalr	1914(ra) # 800027ae <kill_system>
}
    8000303c:	60a2                	ld	ra,8(sp)
    8000303e:	6402                	ld	s0,0(sp)
    80003040:	0141                	addi	sp,sp,16
    80003042:	8082                	ret

0000000080003044 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003044:	7179                	addi	sp,sp,-48
    80003046:	f406                	sd	ra,40(sp)
    80003048:	f022                	sd	s0,32(sp)
    8000304a:	ec26                	sd	s1,24(sp)
    8000304c:	e84a                	sd	s2,16(sp)
    8000304e:	e44e                	sd	s3,8(sp)
    80003050:	e052                	sd	s4,0(sp)
    80003052:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003054:	00005597          	auipc	a1,0x5
    80003058:	4b458593          	addi	a1,a1,1204 # 80008508 <syscalls+0xc0>
    8000305c:	00015517          	auipc	a0,0x15
    80003060:	aac50513          	addi	a0,a0,-1364 # 80017b08 <bcache>
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	af0080e7          	jalr	-1296(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000306c:	0001d797          	auipc	a5,0x1d
    80003070:	a9c78793          	addi	a5,a5,-1380 # 8001fb08 <bcache+0x8000>
    80003074:	0001d717          	auipc	a4,0x1d
    80003078:	cfc70713          	addi	a4,a4,-772 # 8001fd70 <bcache+0x8268>
    8000307c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003080:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003084:	00015497          	auipc	s1,0x15
    80003088:	a9c48493          	addi	s1,s1,-1380 # 80017b20 <bcache+0x18>
    b->next = bcache.head.next;
    8000308c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000308e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003090:	00005a17          	auipc	s4,0x5
    80003094:	480a0a13          	addi	s4,s4,1152 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003098:	2b893783          	ld	a5,696(s2)
    8000309c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000309e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030a2:	85d2                	mv	a1,s4
    800030a4:	01048513          	addi	a0,s1,16
    800030a8:	00001097          	auipc	ra,0x1
    800030ac:	4bc080e7          	jalr	1212(ra) # 80004564 <initsleeplock>
    bcache.head.next->prev = b;
    800030b0:	2b893783          	ld	a5,696(s2)
    800030b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ba:	45848493          	addi	s1,s1,1112
    800030be:	fd349de3          	bne	s1,s3,80003098 <binit+0x54>
  }
}
    800030c2:	70a2                	ld	ra,40(sp)
    800030c4:	7402                	ld	s0,32(sp)
    800030c6:	64e2                	ld	s1,24(sp)
    800030c8:	6942                	ld	s2,16(sp)
    800030ca:	69a2                	ld	s3,8(sp)
    800030cc:	6a02                	ld	s4,0(sp)
    800030ce:	6145                	addi	sp,sp,48
    800030d0:	8082                	ret

00000000800030d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030d2:	7179                	addi	sp,sp,-48
    800030d4:	f406                	sd	ra,40(sp)
    800030d6:	f022                	sd	s0,32(sp)
    800030d8:	ec26                	sd	s1,24(sp)
    800030da:	e84a                	sd	s2,16(sp)
    800030dc:	e44e                	sd	s3,8(sp)
    800030de:	1800                	addi	s0,sp,48
    800030e0:	89aa                	mv	s3,a0
    800030e2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030e4:	00015517          	auipc	a0,0x15
    800030e8:	a2450513          	addi	a0,a0,-1500 # 80017b08 <bcache>
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	af8080e7          	jalr	-1288(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030f4:	0001d497          	auipc	s1,0x1d
    800030f8:	ccc4b483          	ld	s1,-820(s1) # 8001fdc0 <bcache+0x82b8>
    800030fc:	0001d797          	auipc	a5,0x1d
    80003100:	c7478793          	addi	a5,a5,-908 # 8001fd70 <bcache+0x8268>
    80003104:	02f48f63          	beq	s1,a5,80003142 <bread+0x70>
    80003108:	873e                	mv	a4,a5
    8000310a:	a021                	j	80003112 <bread+0x40>
    8000310c:	68a4                	ld	s1,80(s1)
    8000310e:	02e48a63          	beq	s1,a4,80003142 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003112:	449c                	lw	a5,8(s1)
    80003114:	ff379ce3          	bne	a5,s3,8000310c <bread+0x3a>
    80003118:	44dc                	lw	a5,12(s1)
    8000311a:	ff2799e3          	bne	a5,s2,8000310c <bread+0x3a>
      b->refcnt++;
    8000311e:	40bc                	lw	a5,64(s1)
    80003120:	2785                	addiw	a5,a5,1
    80003122:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003124:	00015517          	auipc	a0,0x15
    80003128:	9e450513          	addi	a0,a0,-1564 # 80017b08 <bcache>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003134:	01048513          	addi	a0,s1,16
    80003138:	00001097          	auipc	ra,0x1
    8000313c:	466080e7          	jalr	1126(ra) # 8000459e <acquiresleep>
      return b;
    80003140:	a8b9                	j	8000319e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003142:	0001d497          	auipc	s1,0x1d
    80003146:	c764b483          	ld	s1,-906(s1) # 8001fdb8 <bcache+0x82b0>
    8000314a:	0001d797          	auipc	a5,0x1d
    8000314e:	c2678793          	addi	a5,a5,-986 # 8001fd70 <bcache+0x8268>
    80003152:	00f48863          	beq	s1,a5,80003162 <bread+0x90>
    80003156:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003158:	40bc                	lw	a5,64(s1)
    8000315a:	cf81                	beqz	a5,80003172 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000315c:	64a4                	ld	s1,72(s1)
    8000315e:	fee49de3          	bne	s1,a4,80003158 <bread+0x86>
  panic("bget: no buffers");
    80003162:	00005517          	auipc	a0,0x5
    80003166:	3b650513          	addi	a0,a0,950 # 80008518 <syscalls+0xd0>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>
      b->dev = dev;
    80003172:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003176:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000317a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000317e:	4785                	li	a5,1
    80003180:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003182:	00015517          	auipc	a0,0x15
    80003186:	98650513          	addi	a0,a0,-1658 # 80017b08 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	b0e080e7          	jalr	-1266(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003192:	01048513          	addi	a0,s1,16
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	408080e7          	jalr	1032(ra) # 8000459e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000319e:	409c                	lw	a5,0(s1)
    800031a0:	cb89                	beqz	a5,800031b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031a2:	8526                	mv	a0,s1
    800031a4:	70a2                	ld	ra,40(sp)
    800031a6:	7402                	ld	s0,32(sp)
    800031a8:	64e2                	ld	s1,24(sp)
    800031aa:	6942                	ld	s2,16(sp)
    800031ac:	69a2                	ld	s3,8(sp)
    800031ae:	6145                	addi	sp,sp,48
    800031b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800031b2:	4581                	li	a1,0
    800031b4:	8526                	mv	a0,s1
    800031b6:	00003097          	auipc	ra,0x3
    800031ba:	f10080e7          	jalr	-240(ra) # 800060c6 <virtio_disk_rw>
    b->valid = 1;
    800031be:	4785                	li	a5,1
    800031c0:	c09c                	sw	a5,0(s1)
  return b;
    800031c2:	b7c5                	j	800031a2 <bread+0xd0>

00000000800031c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031c4:	1101                	addi	sp,sp,-32
    800031c6:	ec06                	sd	ra,24(sp)
    800031c8:	e822                	sd	s0,16(sp)
    800031ca:	e426                	sd	s1,8(sp)
    800031cc:	1000                	addi	s0,sp,32
    800031ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031d0:	0541                	addi	a0,a0,16
    800031d2:	00001097          	auipc	ra,0x1
    800031d6:	466080e7          	jalr	1126(ra) # 80004638 <holdingsleep>
    800031da:	cd01                	beqz	a0,800031f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031dc:	4585                	li	a1,1
    800031de:	8526                	mv	a0,s1
    800031e0:	00003097          	auipc	ra,0x3
    800031e4:	ee6080e7          	jalr	-282(ra) # 800060c6 <virtio_disk_rw>
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret
    panic("bwrite");
    800031f2:	00005517          	auipc	a0,0x5
    800031f6:	33e50513          	addi	a0,a0,830 # 80008530 <syscalls+0xe8>
    800031fa:	ffffd097          	auipc	ra,0xffffd
    800031fe:	344080e7          	jalr	836(ra) # 8000053e <panic>

0000000080003202 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	e426                	sd	s1,8(sp)
    8000320a:	e04a                	sd	s2,0(sp)
    8000320c:	1000                	addi	s0,sp,32
    8000320e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003210:	01050913          	addi	s2,a0,16
    80003214:	854a                	mv	a0,s2
    80003216:	00001097          	auipc	ra,0x1
    8000321a:	422080e7          	jalr	1058(ra) # 80004638 <holdingsleep>
    8000321e:	c92d                	beqz	a0,80003290 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003220:	854a                	mv	a0,s2
    80003222:	00001097          	auipc	ra,0x1
    80003226:	3d2080e7          	jalr	978(ra) # 800045f4 <releasesleep>

  acquire(&bcache.lock);
    8000322a:	00015517          	auipc	a0,0x15
    8000322e:	8de50513          	addi	a0,a0,-1826 # 80017b08 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	9b2080e7          	jalr	-1614(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000323a:	40bc                	lw	a5,64(s1)
    8000323c:	37fd                	addiw	a5,a5,-1
    8000323e:	0007871b          	sext.w	a4,a5
    80003242:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003244:	eb05                	bnez	a4,80003274 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003246:	68bc                	ld	a5,80(s1)
    80003248:	64b8                	ld	a4,72(s1)
    8000324a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000324c:	64bc                	ld	a5,72(s1)
    8000324e:	68b8                	ld	a4,80(s1)
    80003250:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003252:	0001d797          	auipc	a5,0x1d
    80003256:	8b678793          	addi	a5,a5,-1866 # 8001fb08 <bcache+0x8000>
    8000325a:	2b87b703          	ld	a4,696(a5)
    8000325e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003260:	0001d717          	auipc	a4,0x1d
    80003264:	b1070713          	addi	a4,a4,-1264 # 8001fd70 <bcache+0x8268>
    80003268:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000326a:	2b87b703          	ld	a4,696(a5)
    8000326e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003270:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003274:	00015517          	auipc	a0,0x15
    80003278:	89450513          	addi	a0,a0,-1900 # 80017b08 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	a1c080e7          	jalr	-1508(ra) # 80000c98 <release>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6902                	ld	s2,0(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret
    panic("brelse");
    80003290:	00005517          	auipc	a0,0x5
    80003294:	2a850513          	addi	a0,a0,680 # 80008538 <syscalls+0xf0>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2a6080e7          	jalr	678(ra) # 8000053e <panic>

00000000800032a0 <bpin>:

void
bpin(struct buf *b) {
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	1000                	addi	s0,sp,32
    800032aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ac:	00015517          	auipc	a0,0x15
    800032b0:	85c50513          	addi	a0,a0,-1956 # 80017b08 <bcache>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	930080e7          	jalr	-1744(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032bc:	40bc                	lw	a5,64(s1)
    800032be:	2785                	addiw	a5,a5,1
    800032c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032c2:	00015517          	auipc	a0,0x15
    800032c6:	84650513          	addi	a0,a0,-1978 # 80017b08 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
}
    800032d2:	60e2                	ld	ra,24(sp)
    800032d4:	6442                	ld	s0,16(sp)
    800032d6:	64a2                	ld	s1,8(sp)
    800032d8:	6105                	addi	sp,sp,32
    800032da:	8082                	ret

00000000800032dc <bunpin>:

void
bunpin(struct buf *b) {
    800032dc:	1101                	addi	sp,sp,-32
    800032de:	ec06                	sd	ra,24(sp)
    800032e0:	e822                	sd	s0,16(sp)
    800032e2:	e426                	sd	s1,8(sp)
    800032e4:	1000                	addi	s0,sp,32
    800032e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e8:	00015517          	auipc	a0,0x15
    800032ec:	82050513          	addi	a0,a0,-2016 # 80017b08 <bcache>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	8f4080e7          	jalr	-1804(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032f8:	40bc                	lw	a5,64(s1)
    800032fa:	37fd                	addiw	a5,a5,-1
    800032fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032fe:	00015517          	auipc	a0,0x15
    80003302:	80a50513          	addi	a0,a0,-2038 # 80017b08 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
}
    8000330e:	60e2                	ld	ra,24(sp)
    80003310:	6442                	ld	s0,16(sp)
    80003312:	64a2                	ld	s1,8(sp)
    80003314:	6105                	addi	sp,sp,32
    80003316:	8082                	ret

0000000080003318 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003318:	1101                	addi	sp,sp,-32
    8000331a:	ec06                	sd	ra,24(sp)
    8000331c:	e822                	sd	s0,16(sp)
    8000331e:	e426                	sd	s1,8(sp)
    80003320:	e04a                	sd	s2,0(sp)
    80003322:	1000                	addi	s0,sp,32
    80003324:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003326:	00d5d59b          	srliw	a1,a1,0xd
    8000332a:	0001d797          	auipc	a5,0x1d
    8000332e:	eba7a783          	lw	a5,-326(a5) # 800201e4 <sb+0x1c>
    80003332:	9dbd                	addw	a1,a1,a5
    80003334:	00000097          	auipc	ra,0x0
    80003338:	d9e080e7          	jalr	-610(ra) # 800030d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000333c:	0074f713          	andi	a4,s1,7
    80003340:	4785                	li	a5,1
    80003342:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003346:	14ce                	slli	s1,s1,0x33
    80003348:	90d9                	srli	s1,s1,0x36
    8000334a:	00950733          	add	a4,a0,s1
    8000334e:	05874703          	lbu	a4,88(a4)
    80003352:	00e7f6b3          	and	a3,a5,a4
    80003356:	c69d                	beqz	a3,80003384 <bfree+0x6c>
    80003358:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000335a:	94aa                	add	s1,s1,a0
    8000335c:	fff7c793          	not	a5,a5
    80003360:	8ff9                	and	a5,a5,a4
    80003362:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003366:	00001097          	auipc	ra,0x1
    8000336a:	118080e7          	jalr	280(ra) # 8000447e <log_write>
  brelse(bp);
    8000336e:	854a                	mv	a0,s2
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e92080e7          	jalr	-366(ra) # 80003202 <brelse>
}
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	64a2                	ld	s1,8(sp)
    8000337e:	6902                	ld	s2,0(sp)
    80003380:	6105                	addi	sp,sp,32
    80003382:	8082                	ret
    panic("freeing free block");
    80003384:	00005517          	auipc	a0,0x5
    80003388:	1bc50513          	addi	a0,a0,444 # 80008540 <syscalls+0xf8>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>

0000000080003394 <balloc>:
{
    80003394:	711d                	addi	sp,sp,-96
    80003396:	ec86                	sd	ra,88(sp)
    80003398:	e8a2                	sd	s0,80(sp)
    8000339a:	e4a6                	sd	s1,72(sp)
    8000339c:	e0ca                	sd	s2,64(sp)
    8000339e:	fc4e                	sd	s3,56(sp)
    800033a0:	f852                	sd	s4,48(sp)
    800033a2:	f456                	sd	s5,40(sp)
    800033a4:	f05a                	sd	s6,32(sp)
    800033a6:	ec5e                	sd	s7,24(sp)
    800033a8:	e862                	sd	s8,16(sp)
    800033aa:	e466                	sd	s9,8(sp)
    800033ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033ae:	0001d797          	auipc	a5,0x1d
    800033b2:	e1e7a783          	lw	a5,-482(a5) # 800201cc <sb+0x4>
    800033b6:	cbd1                	beqz	a5,8000344a <balloc+0xb6>
    800033b8:	8baa                	mv	s7,a0
    800033ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033bc:	0001db17          	auipc	s6,0x1d
    800033c0:	e0cb0b13          	addi	s6,s6,-500 # 800201c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033ca:	6c89                	lui	s9,0x2
    800033cc:	a831                	j	800033e8 <balloc+0x54>
    brelse(bp);
    800033ce:	854a                	mv	a0,s2
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	e32080e7          	jalr	-462(ra) # 80003202 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033d8:	015c87bb          	addw	a5,s9,s5
    800033dc:	00078a9b          	sext.w	s5,a5
    800033e0:	004b2703          	lw	a4,4(s6)
    800033e4:	06eaf363          	bgeu	s5,a4,8000344a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033e8:	41fad79b          	sraiw	a5,s5,0x1f
    800033ec:	0137d79b          	srliw	a5,a5,0x13
    800033f0:	015787bb          	addw	a5,a5,s5
    800033f4:	40d7d79b          	sraiw	a5,a5,0xd
    800033f8:	01cb2583          	lw	a1,28(s6)
    800033fc:	9dbd                	addw	a1,a1,a5
    800033fe:	855e                	mv	a0,s7
    80003400:	00000097          	auipc	ra,0x0
    80003404:	cd2080e7          	jalr	-814(ra) # 800030d2 <bread>
    80003408:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000340a:	004b2503          	lw	a0,4(s6)
    8000340e:	000a849b          	sext.w	s1,s5
    80003412:	8662                	mv	a2,s8
    80003414:	faa4fde3          	bgeu	s1,a0,800033ce <balloc+0x3a>
      m = 1 << (bi % 8);
    80003418:	41f6579b          	sraiw	a5,a2,0x1f
    8000341c:	01d7d69b          	srliw	a3,a5,0x1d
    80003420:	00c6873b          	addw	a4,a3,a2
    80003424:	00777793          	andi	a5,a4,7
    80003428:	9f95                	subw	a5,a5,a3
    8000342a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000342e:	4037571b          	sraiw	a4,a4,0x3
    80003432:	00e906b3          	add	a3,s2,a4
    80003436:	0586c683          	lbu	a3,88(a3)
    8000343a:	00d7f5b3          	and	a1,a5,a3
    8000343e:	cd91                	beqz	a1,8000345a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003440:	2605                	addiw	a2,a2,1
    80003442:	2485                	addiw	s1,s1,1
    80003444:	fd4618e3          	bne	a2,s4,80003414 <balloc+0x80>
    80003448:	b759                	j	800033ce <balloc+0x3a>
  panic("balloc: out of blocks");
    8000344a:	00005517          	auipc	a0,0x5
    8000344e:	10e50513          	addi	a0,a0,270 # 80008558 <syscalls+0x110>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000345a:	974a                	add	a4,a4,s2
    8000345c:	8fd5                	or	a5,a5,a3
    8000345e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003462:	854a                	mv	a0,s2
    80003464:	00001097          	auipc	ra,0x1
    80003468:	01a080e7          	jalr	26(ra) # 8000447e <log_write>
        brelse(bp);
    8000346c:	854a                	mv	a0,s2
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	d94080e7          	jalr	-620(ra) # 80003202 <brelse>
  bp = bread(dev, bno);
    80003476:	85a6                	mv	a1,s1
    80003478:	855e                	mv	a0,s7
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	c58080e7          	jalr	-936(ra) # 800030d2 <bread>
    80003482:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003484:	40000613          	li	a2,1024
    80003488:	4581                	li	a1,0
    8000348a:	05850513          	addi	a0,a0,88
    8000348e:	ffffe097          	auipc	ra,0xffffe
    80003492:	852080e7          	jalr	-1966(ra) # 80000ce0 <memset>
  log_write(bp);
    80003496:	854a                	mv	a0,s2
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	fe6080e7          	jalr	-26(ra) # 8000447e <log_write>
  brelse(bp);
    800034a0:	854a                	mv	a0,s2
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	d60080e7          	jalr	-672(ra) # 80003202 <brelse>
}
    800034aa:	8526                	mv	a0,s1
    800034ac:	60e6                	ld	ra,88(sp)
    800034ae:	6446                	ld	s0,80(sp)
    800034b0:	64a6                	ld	s1,72(sp)
    800034b2:	6906                	ld	s2,64(sp)
    800034b4:	79e2                	ld	s3,56(sp)
    800034b6:	7a42                	ld	s4,48(sp)
    800034b8:	7aa2                	ld	s5,40(sp)
    800034ba:	7b02                	ld	s6,32(sp)
    800034bc:	6be2                	ld	s7,24(sp)
    800034be:	6c42                	ld	s8,16(sp)
    800034c0:	6ca2                	ld	s9,8(sp)
    800034c2:	6125                	addi	sp,sp,96
    800034c4:	8082                	ret

00000000800034c6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034c6:	7179                	addi	sp,sp,-48
    800034c8:	f406                	sd	ra,40(sp)
    800034ca:	f022                	sd	s0,32(sp)
    800034cc:	ec26                	sd	s1,24(sp)
    800034ce:	e84a                	sd	s2,16(sp)
    800034d0:	e44e                	sd	s3,8(sp)
    800034d2:	e052                	sd	s4,0(sp)
    800034d4:	1800                	addi	s0,sp,48
    800034d6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034d8:	47ad                	li	a5,11
    800034da:	04b7fe63          	bgeu	a5,a1,80003536 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034de:	ff45849b          	addiw	s1,a1,-12
    800034e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034e6:	0ff00793          	li	a5,255
    800034ea:	0ae7e363          	bltu	a5,a4,80003590 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034ee:	08052583          	lw	a1,128(a0)
    800034f2:	c5ad                	beqz	a1,8000355c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034f4:	00092503          	lw	a0,0(s2)
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	bda080e7          	jalr	-1062(ra) # 800030d2 <bread>
    80003500:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003502:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003506:	02049593          	slli	a1,s1,0x20
    8000350a:	9181                	srli	a1,a1,0x20
    8000350c:	058a                	slli	a1,a1,0x2
    8000350e:	00b784b3          	add	s1,a5,a1
    80003512:	0004a983          	lw	s3,0(s1)
    80003516:	04098d63          	beqz	s3,80003570 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000351a:	8552                	mv	a0,s4
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	ce6080e7          	jalr	-794(ra) # 80003202 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003524:	854e                	mv	a0,s3
    80003526:	70a2                	ld	ra,40(sp)
    80003528:	7402                	ld	s0,32(sp)
    8000352a:	64e2                	ld	s1,24(sp)
    8000352c:	6942                	ld	s2,16(sp)
    8000352e:	69a2                	ld	s3,8(sp)
    80003530:	6a02                	ld	s4,0(sp)
    80003532:	6145                	addi	sp,sp,48
    80003534:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003536:	02059493          	slli	s1,a1,0x20
    8000353a:	9081                	srli	s1,s1,0x20
    8000353c:	048a                	slli	s1,s1,0x2
    8000353e:	94aa                	add	s1,s1,a0
    80003540:	0504a983          	lw	s3,80(s1)
    80003544:	fe0990e3          	bnez	s3,80003524 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003548:	4108                	lw	a0,0(a0)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	e4a080e7          	jalr	-438(ra) # 80003394 <balloc>
    80003552:	0005099b          	sext.w	s3,a0
    80003556:	0534a823          	sw	s3,80(s1)
    8000355a:	b7e9                	j	80003524 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000355c:	4108                	lw	a0,0(a0)
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	e36080e7          	jalr	-458(ra) # 80003394 <balloc>
    80003566:	0005059b          	sext.w	a1,a0
    8000356a:	08b92023          	sw	a1,128(s2)
    8000356e:	b759                	j	800034f4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003570:	00092503          	lw	a0,0(s2)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	e20080e7          	jalr	-480(ra) # 80003394 <balloc>
    8000357c:	0005099b          	sext.w	s3,a0
    80003580:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003584:	8552                	mv	a0,s4
    80003586:	00001097          	auipc	ra,0x1
    8000358a:	ef8080e7          	jalr	-264(ra) # 8000447e <log_write>
    8000358e:	b771                	j	8000351a <bmap+0x54>
  panic("bmap: out of range");
    80003590:	00005517          	auipc	a0,0x5
    80003594:	fe050513          	addi	a0,a0,-32 # 80008570 <syscalls+0x128>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	fa6080e7          	jalr	-90(ra) # 8000053e <panic>

00000000800035a0 <iget>:
{
    800035a0:	7179                	addi	sp,sp,-48
    800035a2:	f406                	sd	ra,40(sp)
    800035a4:	f022                	sd	s0,32(sp)
    800035a6:	ec26                	sd	s1,24(sp)
    800035a8:	e84a                	sd	s2,16(sp)
    800035aa:	e44e                	sd	s3,8(sp)
    800035ac:	e052                	sd	s4,0(sp)
    800035ae:	1800                	addi	s0,sp,48
    800035b0:	89aa                	mv	s3,a0
    800035b2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035b4:	0001d517          	auipc	a0,0x1d
    800035b8:	c3450513          	addi	a0,a0,-972 # 800201e8 <itable>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	628080e7          	jalr	1576(ra) # 80000be4 <acquire>
  empty = 0;
    800035c4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035c6:	0001d497          	auipc	s1,0x1d
    800035ca:	c3a48493          	addi	s1,s1,-966 # 80020200 <itable+0x18>
    800035ce:	0001e697          	auipc	a3,0x1e
    800035d2:	6c268693          	addi	a3,a3,1730 # 80021c90 <log>
    800035d6:	a039                	j	800035e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d8:	02090b63          	beqz	s2,8000360e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035dc:	08848493          	addi	s1,s1,136
    800035e0:	02d48a63          	beq	s1,a3,80003614 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035e4:	449c                	lw	a5,8(s1)
    800035e6:	fef059e3          	blez	a5,800035d8 <iget+0x38>
    800035ea:	4098                	lw	a4,0(s1)
    800035ec:	ff3716e3          	bne	a4,s3,800035d8 <iget+0x38>
    800035f0:	40d8                	lw	a4,4(s1)
    800035f2:	ff4713e3          	bne	a4,s4,800035d8 <iget+0x38>
      ip->ref++;
    800035f6:	2785                	addiw	a5,a5,1
    800035f8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035fa:	0001d517          	auipc	a0,0x1d
    800035fe:	bee50513          	addi	a0,a0,-1042 # 800201e8 <itable>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	696080e7          	jalr	1686(ra) # 80000c98 <release>
      return ip;
    8000360a:	8926                	mv	s2,s1
    8000360c:	a03d                	j	8000363a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000360e:	f7f9                	bnez	a5,800035dc <iget+0x3c>
    80003610:	8926                	mv	s2,s1
    80003612:	b7e9                	j	800035dc <iget+0x3c>
  if(empty == 0)
    80003614:	02090c63          	beqz	s2,8000364c <iget+0xac>
  ip->dev = dev;
    80003618:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000361c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003620:	4785                	li	a5,1
    80003622:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003626:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000362a:	0001d517          	auipc	a0,0x1d
    8000362e:	bbe50513          	addi	a0,a0,-1090 # 800201e8 <itable>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
}
    8000363a:	854a                	mv	a0,s2
    8000363c:	70a2                	ld	ra,40(sp)
    8000363e:	7402                	ld	s0,32(sp)
    80003640:	64e2                	ld	s1,24(sp)
    80003642:	6942                	ld	s2,16(sp)
    80003644:	69a2                	ld	s3,8(sp)
    80003646:	6a02                	ld	s4,0(sp)
    80003648:	6145                	addi	sp,sp,48
    8000364a:	8082                	ret
    panic("iget: no inodes");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	f3c50513          	addi	a0,a0,-196 # 80008588 <syscalls+0x140>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	eea080e7          	jalr	-278(ra) # 8000053e <panic>

000000008000365c <fsinit>:
fsinit(int dev) {
    8000365c:	7179                	addi	sp,sp,-48
    8000365e:	f406                	sd	ra,40(sp)
    80003660:	f022                	sd	s0,32(sp)
    80003662:	ec26                	sd	s1,24(sp)
    80003664:	e84a                	sd	s2,16(sp)
    80003666:	e44e                	sd	s3,8(sp)
    80003668:	1800                	addi	s0,sp,48
    8000366a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000366c:	4585                	li	a1,1
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	a64080e7          	jalr	-1436(ra) # 800030d2 <bread>
    80003676:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003678:	0001d997          	auipc	s3,0x1d
    8000367c:	b5098993          	addi	s3,s3,-1200 # 800201c8 <sb>
    80003680:	02000613          	li	a2,32
    80003684:	05850593          	addi	a1,a0,88
    80003688:	854e                	mv	a0,s3
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	6b6080e7          	jalr	1718(ra) # 80000d40 <memmove>
  brelse(bp);
    80003692:	8526                	mv	a0,s1
    80003694:	00000097          	auipc	ra,0x0
    80003698:	b6e080e7          	jalr	-1170(ra) # 80003202 <brelse>
  if(sb.magic != FSMAGIC)
    8000369c:	0009a703          	lw	a4,0(s3)
    800036a0:	102037b7          	lui	a5,0x10203
    800036a4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036a8:	02f71263          	bne	a4,a5,800036cc <fsinit+0x70>
  initlog(dev, &sb);
    800036ac:	0001d597          	auipc	a1,0x1d
    800036b0:	b1c58593          	addi	a1,a1,-1252 # 800201c8 <sb>
    800036b4:	854a                	mv	a0,s2
    800036b6:	00001097          	auipc	ra,0x1
    800036ba:	b4c080e7          	jalr	-1204(ra) # 80004202 <initlog>
}
    800036be:	70a2                	ld	ra,40(sp)
    800036c0:	7402                	ld	s0,32(sp)
    800036c2:	64e2                	ld	s1,24(sp)
    800036c4:	6942                	ld	s2,16(sp)
    800036c6:	69a2                	ld	s3,8(sp)
    800036c8:	6145                	addi	sp,sp,48
    800036ca:	8082                	ret
    panic("invalid file system");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	ecc50513          	addi	a0,a0,-308 # 80008598 <syscalls+0x150>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>

00000000800036dc <iinit>:
{
    800036dc:	7179                	addi	sp,sp,-48
    800036de:	f406                	sd	ra,40(sp)
    800036e0:	f022                	sd	s0,32(sp)
    800036e2:	ec26                	sd	s1,24(sp)
    800036e4:	e84a                	sd	s2,16(sp)
    800036e6:	e44e                	sd	s3,8(sp)
    800036e8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036ea:	00005597          	auipc	a1,0x5
    800036ee:	ec658593          	addi	a1,a1,-314 # 800085b0 <syscalls+0x168>
    800036f2:	0001d517          	auipc	a0,0x1d
    800036f6:	af650513          	addi	a0,a0,-1290 # 800201e8 <itable>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	45a080e7          	jalr	1114(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003702:	0001d497          	auipc	s1,0x1d
    80003706:	b0e48493          	addi	s1,s1,-1266 # 80020210 <itable+0x28>
    8000370a:	0001e997          	auipc	s3,0x1e
    8000370e:	59698993          	addi	s3,s3,1430 # 80021ca0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003712:	00005917          	auipc	s2,0x5
    80003716:	ea690913          	addi	s2,s2,-346 # 800085b8 <syscalls+0x170>
    8000371a:	85ca                	mv	a1,s2
    8000371c:	8526                	mv	a0,s1
    8000371e:	00001097          	auipc	ra,0x1
    80003722:	e46080e7          	jalr	-442(ra) # 80004564 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003726:	08848493          	addi	s1,s1,136
    8000372a:	ff3498e3          	bne	s1,s3,8000371a <iinit+0x3e>
}
    8000372e:	70a2                	ld	ra,40(sp)
    80003730:	7402                	ld	s0,32(sp)
    80003732:	64e2                	ld	s1,24(sp)
    80003734:	6942                	ld	s2,16(sp)
    80003736:	69a2                	ld	s3,8(sp)
    80003738:	6145                	addi	sp,sp,48
    8000373a:	8082                	ret

000000008000373c <ialloc>:
{
    8000373c:	715d                	addi	sp,sp,-80
    8000373e:	e486                	sd	ra,72(sp)
    80003740:	e0a2                	sd	s0,64(sp)
    80003742:	fc26                	sd	s1,56(sp)
    80003744:	f84a                	sd	s2,48(sp)
    80003746:	f44e                	sd	s3,40(sp)
    80003748:	f052                	sd	s4,32(sp)
    8000374a:	ec56                	sd	s5,24(sp)
    8000374c:	e85a                	sd	s6,16(sp)
    8000374e:	e45e                	sd	s7,8(sp)
    80003750:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003752:	0001d717          	auipc	a4,0x1d
    80003756:	a8272703          	lw	a4,-1406(a4) # 800201d4 <sb+0xc>
    8000375a:	4785                	li	a5,1
    8000375c:	04e7fa63          	bgeu	a5,a4,800037b0 <ialloc+0x74>
    80003760:	8aaa                	mv	s5,a0
    80003762:	8bae                	mv	s7,a1
    80003764:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003766:	0001da17          	auipc	s4,0x1d
    8000376a:	a62a0a13          	addi	s4,s4,-1438 # 800201c8 <sb>
    8000376e:	00048b1b          	sext.w	s6,s1
    80003772:	0044d593          	srli	a1,s1,0x4
    80003776:	018a2783          	lw	a5,24(s4)
    8000377a:	9dbd                	addw	a1,a1,a5
    8000377c:	8556                	mv	a0,s5
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	954080e7          	jalr	-1708(ra) # 800030d2 <bread>
    80003786:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003788:	05850993          	addi	s3,a0,88
    8000378c:	00f4f793          	andi	a5,s1,15
    80003790:	079a                	slli	a5,a5,0x6
    80003792:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003794:	00099783          	lh	a5,0(s3)
    80003798:	c785                	beqz	a5,800037c0 <ialloc+0x84>
    brelse(bp);
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	a68080e7          	jalr	-1432(ra) # 80003202 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037a2:	0485                	addi	s1,s1,1
    800037a4:	00ca2703          	lw	a4,12(s4)
    800037a8:	0004879b          	sext.w	a5,s1
    800037ac:	fce7e1e3          	bltu	a5,a4,8000376e <ialloc+0x32>
  panic("ialloc: no inodes");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	e1050513          	addi	a0,a0,-496 # 800085c0 <syscalls+0x178>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d86080e7          	jalr	-634(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037c0:	04000613          	li	a2,64
    800037c4:	4581                	li	a1,0
    800037c6:	854e                	mv	a0,s3
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	518080e7          	jalr	1304(ra) # 80000ce0 <memset>
      dip->type = type;
    800037d0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037d4:	854a                	mv	a0,s2
    800037d6:	00001097          	auipc	ra,0x1
    800037da:	ca8080e7          	jalr	-856(ra) # 8000447e <log_write>
      brelse(bp);
    800037de:	854a                	mv	a0,s2
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	a22080e7          	jalr	-1502(ra) # 80003202 <brelse>
      return iget(dev, inum);
    800037e8:	85da                	mv	a1,s6
    800037ea:	8556                	mv	a0,s5
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	db4080e7          	jalr	-588(ra) # 800035a0 <iget>
}
    800037f4:	60a6                	ld	ra,72(sp)
    800037f6:	6406                	ld	s0,64(sp)
    800037f8:	74e2                	ld	s1,56(sp)
    800037fa:	7942                	ld	s2,48(sp)
    800037fc:	79a2                	ld	s3,40(sp)
    800037fe:	7a02                	ld	s4,32(sp)
    80003800:	6ae2                	ld	s5,24(sp)
    80003802:	6b42                	ld	s6,16(sp)
    80003804:	6ba2                	ld	s7,8(sp)
    80003806:	6161                	addi	sp,sp,80
    80003808:	8082                	ret

000000008000380a <iupdate>:
{
    8000380a:	1101                	addi	sp,sp,-32
    8000380c:	ec06                	sd	ra,24(sp)
    8000380e:	e822                	sd	s0,16(sp)
    80003810:	e426                	sd	s1,8(sp)
    80003812:	e04a                	sd	s2,0(sp)
    80003814:	1000                	addi	s0,sp,32
    80003816:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003818:	415c                	lw	a5,4(a0)
    8000381a:	0047d79b          	srliw	a5,a5,0x4
    8000381e:	0001d597          	auipc	a1,0x1d
    80003822:	9c25a583          	lw	a1,-1598(a1) # 800201e0 <sb+0x18>
    80003826:	9dbd                	addw	a1,a1,a5
    80003828:	4108                	lw	a0,0(a0)
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	8a8080e7          	jalr	-1880(ra) # 800030d2 <bread>
    80003832:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003834:	05850793          	addi	a5,a0,88
    80003838:	40c8                	lw	a0,4(s1)
    8000383a:	893d                	andi	a0,a0,15
    8000383c:	051a                	slli	a0,a0,0x6
    8000383e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003840:	04449703          	lh	a4,68(s1)
    80003844:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003848:	04649703          	lh	a4,70(s1)
    8000384c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003850:	04849703          	lh	a4,72(s1)
    80003854:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003858:	04a49703          	lh	a4,74(s1)
    8000385c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003860:	44f8                	lw	a4,76(s1)
    80003862:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003864:	03400613          	li	a2,52
    80003868:	05048593          	addi	a1,s1,80
    8000386c:	0531                	addi	a0,a0,12
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	4d2080e7          	jalr	1234(ra) # 80000d40 <memmove>
  log_write(bp);
    80003876:	854a                	mv	a0,s2
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	c06080e7          	jalr	-1018(ra) # 8000447e <log_write>
  brelse(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00000097          	auipc	ra,0x0
    80003886:	980080e7          	jalr	-1664(ra) # 80003202 <brelse>
}
    8000388a:	60e2                	ld	ra,24(sp)
    8000388c:	6442                	ld	s0,16(sp)
    8000388e:	64a2                	ld	s1,8(sp)
    80003890:	6902                	ld	s2,0(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret

0000000080003896 <idup>:
{
    80003896:	1101                	addi	sp,sp,-32
    80003898:	ec06                	sd	ra,24(sp)
    8000389a:	e822                	sd	s0,16(sp)
    8000389c:	e426                	sd	s1,8(sp)
    8000389e:	1000                	addi	s0,sp,32
    800038a0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038a2:	0001d517          	auipc	a0,0x1d
    800038a6:	94650513          	addi	a0,a0,-1722 # 800201e8 <itable>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	33a080e7          	jalr	826(ra) # 80000be4 <acquire>
  ip->ref++;
    800038b2:	449c                	lw	a5,8(s1)
    800038b4:	2785                	addiw	a5,a5,1
    800038b6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038b8:	0001d517          	auipc	a0,0x1d
    800038bc:	93050513          	addi	a0,a0,-1744 # 800201e8 <itable>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	3d8080e7          	jalr	984(ra) # 80000c98 <release>
}
    800038c8:	8526                	mv	a0,s1
    800038ca:	60e2                	ld	ra,24(sp)
    800038cc:	6442                	ld	s0,16(sp)
    800038ce:	64a2                	ld	s1,8(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret

00000000800038d4 <ilock>:
{
    800038d4:	1101                	addi	sp,sp,-32
    800038d6:	ec06                	sd	ra,24(sp)
    800038d8:	e822                	sd	s0,16(sp)
    800038da:	e426                	sd	s1,8(sp)
    800038dc:	e04a                	sd	s2,0(sp)
    800038de:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038e0:	c115                	beqz	a0,80003904 <ilock+0x30>
    800038e2:	84aa                	mv	s1,a0
    800038e4:	451c                	lw	a5,8(a0)
    800038e6:	00f05f63          	blez	a5,80003904 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038ea:	0541                	addi	a0,a0,16
    800038ec:	00001097          	auipc	ra,0x1
    800038f0:	cb2080e7          	jalr	-846(ra) # 8000459e <acquiresleep>
  if(ip->valid == 0){
    800038f4:	40bc                	lw	a5,64(s1)
    800038f6:	cf99                	beqz	a5,80003914 <ilock+0x40>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6902                	ld	s2,0(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret
    panic("ilock");
    80003904:	00005517          	auipc	a0,0x5
    80003908:	cd450513          	addi	a0,a0,-812 # 800085d8 <syscalls+0x190>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	c32080e7          	jalr	-974(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003914:	40dc                	lw	a5,4(s1)
    80003916:	0047d79b          	srliw	a5,a5,0x4
    8000391a:	0001d597          	auipc	a1,0x1d
    8000391e:	8c65a583          	lw	a1,-1850(a1) # 800201e0 <sb+0x18>
    80003922:	9dbd                	addw	a1,a1,a5
    80003924:	4088                	lw	a0,0(s1)
    80003926:	fffff097          	auipc	ra,0xfffff
    8000392a:	7ac080e7          	jalr	1964(ra) # 800030d2 <bread>
    8000392e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003930:	05850593          	addi	a1,a0,88
    80003934:	40dc                	lw	a5,4(s1)
    80003936:	8bbd                	andi	a5,a5,15
    80003938:	079a                	slli	a5,a5,0x6
    8000393a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000393c:	00059783          	lh	a5,0(a1)
    80003940:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003944:	00259783          	lh	a5,2(a1)
    80003948:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000394c:	00459783          	lh	a5,4(a1)
    80003950:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003954:	00659783          	lh	a5,6(a1)
    80003958:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000395c:	459c                	lw	a5,8(a1)
    8000395e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003960:	03400613          	li	a2,52
    80003964:	05b1                	addi	a1,a1,12
    80003966:	05048513          	addi	a0,s1,80
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	3d6080e7          	jalr	982(ra) # 80000d40 <memmove>
    brelse(bp);
    80003972:	854a                	mv	a0,s2
    80003974:	00000097          	auipc	ra,0x0
    80003978:	88e080e7          	jalr	-1906(ra) # 80003202 <brelse>
    ip->valid = 1;
    8000397c:	4785                	li	a5,1
    8000397e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003980:	04449783          	lh	a5,68(s1)
    80003984:	fbb5                	bnez	a5,800038f8 <ilock+0x24>
      panic("ilock: no type");
    80003986:	00005517          	auipc	a0,0x5
    8000398a:	c5a50513          	addi	a0,a0,-934 # 800085e0 <syscalls+0x198>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>

0000000080003996 <iunlock>:
{
    80003996:	1101                	addi	sp,sp,-32
    80003998:	ec06                	sd	ra,24(sp)
    8000399a:	e822                	sd	s0,16(sp)
    8000399c:	e426                	sd	s1,8(sp)
    8000399e:	e04a                	sd	s2,0(sp)
    800039a0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039a2:	c905                	beqz	a0,800039d2 <iunlock+0x3c>
    800039a4:	84aa                	mv	s1,a0
    800039a6:	01050913          	addi	s2,a0,16
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	c8c080e7          	jalr	-884(ra) # 80004638 <holdingsleep>
    800039b4:	cd19                	beqz	a0,800039d2 <iunlock+0x3c>
    800039b6:	449c                	lw	a5,8(s1)
    800039b8:	00f05d63          	blez	a5,800039d2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039bc:	854a                	mv	a0,s2
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	c36080e7          	jalr	-970(ra) # 800045f4 <releasesleep>
}
    800039c6:	60e2                	ld	ra,24(sp)
    800039c8:	6442                	ld	s0,16(sp)
    800039ca:	64a2                	ld	s1,8(sp)
    800039cc:	6902                	ld	s2,0(sp)
    800039ce:	6105                	addi	sp,sp,32
    800039d0:	8082                	ret
    panic("iunlock");
    800039d2:	00005517          	auipc	a0,0x5
    800039d6:	c1e50513          	addi	a0,a0,-994 # 800085f0 <syscalls+0x1a8>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>

00000000800039e2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039e2:	7179                	addi	sp,sp,-48
    800039e4:	f406                	sd	ra,40(sp)
    800039e6:	f022                	sd	s0,32(sp)
    800039e8:	ec26                	sd	s1,24(sp)
    800039ea:	e84a                	sd	s2,16(sp)
    800039ec:	e44e                	sd	s3,8(sp)
    800039ee:	e052                	sd	s4,0(sp)
    800039f0:	1800                	addi	s0,sp,48
    800039f2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039f4:	05050493          	addi	s1,a0,80
    800039f8:	08050913          	addi	s2,a0,128
    800039fc:	a021                	j	80003a04 <itrunc+0x22>
    800039fe:	0491                	addi	s1,s1,4
    80003a00:	01248d63          	beq	s1,s2,80003a1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a04:	408c                	lw	a1,0(s1)
    80003a06:	dde5                	beqz	a1,800039fe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a08:	0009a503          	lw	a0,0(s3)
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	90c080e7          	jalr	-1780(ra) # 80003318 <bfree>
      ip->addrs[i] = 0;
    80003a14:	0004a023          	sw	zero,0(s1)
    80003a18:	b7dd                	j	800039fe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a1a:	0809a583          	lw	a1,128(s3)
    80003a1e:	e185                	bnez	a1,80003a3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a24:	854e                	mv	a0,s3
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	de4080e7          	jalr	-540(ra) # 8000380a <iupdate>
}
    80003a2e:	70a2                	ld	ra,40(sp)
    80003a30:	7402                	ld	s0,32(sp)
    80003a32:	64e2                	ld	s1,24(sp)
    80003a34:	6942                	ld	s2,16(sp)
    80003a36:	69a2                	ld	s3,8(sp)
    80003a38:	6a02                	ld	s4,0(sp)
    80003a3a:	6145                	addi	sp,sp,48
    80003a3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a3e:	0009a503          	lw	a0,0(s3)
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	690080e7          	jalr	1680(ra) # 800030d2 <bread>
    80003a4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a4c:	05850493          	addi	s1,a0,88
    80003a50:	45850913          	addi	s2,a0,1112
    80003a54:	a811                	j	80003a68 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a56:	0009a503          	lw	a0,0(s3)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	8be080e7          	jalr	-1858(ra) # 80003318 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a62:	0491                	addi	s1,s1,4
    80003a64:	01248563          	beq	s1,s2,80003a6e <itrunc+0x8c>
      if(a[j])
    80003a68:	408c                	lw	a1,0(s1)
    80003a6a:	dde5                	beqz	a1,80003a62 <itrunc+0x80>
    80003a6c:	b7ed                	j	80003a56 <itrunc+0x74>
    brelse(bp);
    80003a6e:	8552                	mv	a0,s4
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	792080e7          	jalr	1938(ra) # 80003202 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a78:	0809a583          	lw	a1,128(s3)
    80003a7c:	0009a503          	lw	a0,0(s3)
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	898080e7          	jalr	-1896(ra) # 80003318 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a88:	0809a023          	sw	zero,128(s3)
    80003a8c:	bf51                	j	80003a20 <itrunc+0x3e>

0000000080003a8e <iput>:
{
    80003a8e:	1101                	addi	sp,sp,-32
    80003a90:	ec06                	sd	ra,24(sp)
    80003a92:	e822                	sd	s0,16(sp)
    80003a94:	e426                	sd	s1,8(sp)
    80003a96:	e04a                	sd	s2,0(sp)
    80003a98:	1000                	addi	s0,sp,32
    80003a9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a9c:	0001c517          	auipc	a0,0x1c
    80003aa0:	74c50513          	addi	a0,a0,1868 # 800201e8 <itable>
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	140080e7          	jalr	320(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aac:	4498                	lw	a4,8(s1)
    80003aae:	4785                	li	a5,1
    80003ab0:	02f70363          	beq	a4,a5,80003ad6 <iput+0x48>
  ip->ref--;
    80003ab4:	449c                	lw	a5,8(s1)
    80003ab6:	37fd                	addiw	a5,a5,-1
    80003ab8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aba:	0001c517          	auipc	a0,0x1c
    80003abe:	72e50513          	addi	a0,a0,1838 # 800201e8 <itable>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	1d6080e7          	jalr	470(ra) # 80000c98 <release>
}
    80003aca:	60e2                	ld	ra,24(sp)
    80003acc:	6442                	ld	s0,16(sp)
    80003ace:	64a2                	ld	s1,8(sp)
    80003ad0:	6902                	ld	s2,0(sp)
    80003ad2:	6105                	addi	sp,sp,32
    80003ad4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad6:	40bc                	lw	a5,64(s1)
    80003ad8:	dff1                	beqz	a5,80003ab4 <iput+0x26>
    80003ada:	04a49783          	lh	a5,74(s1)
    80003ade:	fbf9                	bnez	a5,80003ab4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ae0:	01048913          	addi	s2,s1,16
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	00001097          	auipc	ra,0x1
    80003aea:	ab8080e7          	jalr	-1352(ra) # 8000459e <acquiresleep>
    release(&itable.lock);
    80003aee:	0001c517          	auipc	a0,0x1c
    80003af2:	6fa50513          	addi	a0,a0,1786 # 800201e8 <itable>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>
    itrunc(ip);
    80003afe:	8526                	mv	a0,s1
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	ee2080e7          	jalr	-286(ra) # 800039e2 <itrunc>
    ip->type = 0;
    80003b08:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b0c:	8526                	mv	a0,s1
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	cfc080e7          	jalr	-772(ra) # 8000380a <iupdate>
    ip->valid = 0;
    80003b16:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	00001097          	auipc	ra,0x1
    80003b20:	ad8080e7          	jalr	-1320(ra) # 800045f4 <releasesleep>
    acquire(&itable.lock);
    80003b24:	0001c517          	auipc	a0,0x1c
    80003b28:	6c450513          	addi	a0,a0,1732 # 800201e8 <itable>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	0b8080e7          	jalr	184(ra) # 80000be4 <acquire>
    80003b34:	b741                	j	80003ab4 <iput+0x26>

0000000080003b36 <iunlockput>:
{
    80003b36:	1101                	addi	sp,sp,-32
    80003b38:	ec06                	sd	ra,24(sp)
    80003b3a:	e822                	sd	s0,16(sp)
    80003b3c:	e426                	sd	s1,8(sp)
    80003b3e:	1000                	addi	s0,sp,32
    80003b40:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	e54080e7          	jalr	-428(ra) # 80003996 <iunlock>
  iput(ip);
    80003b4a:	8526                	mv	a0,s1
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	f42080e7          	jalr	-190(ra) # 80003a8e <iput>
}
    80003b54:	60e2                	ld	ra,24(sp)
    80003b56:	6442                	ld	s0,16(sp)
    80003b58:	64a2                	ld	s1,8(sp)
    80003b5a:	6105                	addi	sp,sp,32
    80003b5c:	8082                	ret

0000000080003b5e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b5e:	1141                	addi	sp,sp,-16
    80003b60:	e422                	sd	s0,8(sp)
    80003b62:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b64:	411c                	lw	a5,0(a0)
    80003b66:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b68:	415c                	lw	a5,4(a0)
    80003b6a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b6c:	04451783          	lh	a5,68(a0)
    80003b70:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b74:	04a51783          	lh	a5,74(a0)
    80003b78:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b7c:	04c56783          	lwu	a5,76(a0)
    80003b80:	e99c                	sd	a5,16(a1)
}
    80003b82:	6422                	ld	s0,8(sp)
    80003b84:	0141                	addi	sp,sp,16
    80003b86:	8082                	ret

0000000080003b88 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b88:	457c                	lw	a5,76(a0)
    80003b8a:	0ed7e963          	bltu	a5,a3,80003c7c <readi+0xf4>
{
    80003b8e:	7159                	addi	sp,sp,-112
    80003b90:	f486                	sd	ra,104(sp)
    80003b92:	f0a2                	sd	s0,96(sp)
    80003b94:	eca6                	sd	s1,88(sp)
    80003b96:	e8ca                	sd	s2,80(sp)
    80003b98:	e4ce                	sd	s3,72(sp)
    80003b9a:	e0d2                	sd	s4,64(sp)
    80003b9c:	fc56                	sd	s5,56(sp)
    80003b9e:	f85a                	sd	s6,48(sp)
    80003ba0:	f45e                	sd	s7,40(sp)
    80003ba2:	f062                	sd	s8,32(sp)
    80003ba4:	ec66                	sd	s9,24(sp)
    80003ba6:	e86a                	sd	s10,16(sp)
    80003ba8:	e46e                	sd	s11,8(sp)
    80003baa:	1880                	addi	s0,sp,112
    80003bac:	8baa                	mv	s7,a0
    80003bae:	8c2e                	mv	s8,a1
    80003bb0:	8ab2                	mv	s5,a2
    80003bb2:	84b6                	mv	s1,a3
    80003bb4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bb6:	9f35                	addw	a4,a4,a3
    return 0;
    80003bb8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bba:	0ad76063          	bltu	a4,a3,80003c5a <readi+0xd2>
  if(off + n > ip->size)
    80003bbe:	00e7f463          	bgeu	a5,a4,80003bc6 <readi+0x3e>
    n = ip->size - off;
    80003bc2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc6:	0a0b0963          	beqz	s6,80003c78 <readi+0xf0>
    80003bca:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bcc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bd0:	5cfd                	li	s9,-1
    80003bd2:	a82d                	j	80003c0c <readi+0x84>
    80003bd4:	020a1d93          	slli	s11,s4,0x20
    80003bd8:	020ddd93          	srli	s11,s11,0x20
    80003bdc:	05890613          	addi	a2,s2,88
    80003be0:	86ee                	mv	a3,s11
    80003be2:	963a                	add	a2,a2,a4
    80003be4:	85d6                	mv	a1,s5
    80003be6:	8562                	mv	a0,s8
    80003be8:	ffffe097          	auipc	ra,0xffffe
    80003bec:	426080e7          	jalr	1062(ra) # 8000200e <either_copyout>
    80003bf0:	05950d63          	beq	a0,s9,80003c4a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	60c080e7          	jalr	1548(ra) # 80003202 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfe:	013a09bb          	addw	s3,s4,s3
    80003c02:	009a04bb          	addw	s1,s4,s1
    80003c06:	9aee                	add	s5,s5,s11
    80003c08:	0569f763          	bgeu	s3,s6,80003c56 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c0c:	000ba903          	lw	s2,0(s7)
    80003c10:	00a4d59b          	srliw	a1,s1,0xa
    80003c14:	855e                	mv	a0,s7
    80003c16:	00000097          	auipc	ra,0x0
    80003c1a:	8b0080e7          	jalr	-1872(ra) # 800034c6 <bmap>
    80003c1e:	0005059b          	sext.w	a1,a0
    80003c22:	854a                	mv	a0,s2
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	4ae080e7          	jalr	1198(ra) # 800030d2 <bread>
    80003c2c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2e:	3ff4f713          	andi	a4,s1,1023
    80003c32:	40ed07bb          	subw	a5,s10,a4
    80003c36:	413b06bb          	subw	a3,s6,s3
    80003c3a:	8a3e                	mv	s4,a5
    80003c3c:	2781                	sext.w	a5,a5
    80003c3e:	0006861b          	sext.w	a2,a3
    80003c42:	f8f679e3          	bgeu	a2,a5,80003bd4 <readi+0x4c>
    80003c46:	8a36                	mv	s4,a3
    80003c48:	b771                	j	80003bd4 <readi+0x4c>
      brelse(bp);
    80003c4a:	854a                	mv	a0,s2
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	5b6080e7          	jalr	1462(ra) # 80003202 <brelse>
      tot = -1;
    80003c54:	59fd                	li	s3,-1
  }
  return tot;
    80003c56:	0009851b          	sext.w	a0,s3
}
    80003c5a:	70a6                	ld	ra,104(sp)
    80003c5c:	7406                	ld	s0,96(sp)
    80003c5e:	64e6                	ld	s1,88(sp)
    80003c60:	6946                	ld	s2,80(sp)
    80003c62:	69a6                	ld	s3,72(sp)
    80003c64:	6a06                	ld	s4,64(sp)
    80003c66:	7ae2                	ld	s5,56(sp)
    80003c68:	7b42                	ld	s6,48(sp)
    80003c6a:	7ba2                	ld	s7,40(sp)
    80003c6c:	7c02                	ld	s8,32(sp)
    80003c6e:	6ce2                	ld	s9,24(sp)
    80003c70:	6d42                	ld	s10,16(sp)
    80003c72:	6da2                	ld	s11,8(sp)
    80003c74:	6165                	addi	sp,sp,112
    80003c76:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c78:	89da                	mv	s3,s6
    80003c7a:	bff1                	j	80003c56 <readi+0xce>
    return 0;
    80003c7c:	4501                	li	a0,0
}
    80003c7e:	8082                	ret

0000000080003c80 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c80:	457c                	lw	a5,76(a0)
    80003c82:	10d7e863          	bltu	a5,a3,80003d92 <writei+0x112>
{
    80003c86:	7159                	addi	sp,sp,-112
    80003c88:	f486                	sd	ra,104(sp)
    80003c8a:	f0a2                	sd	s0,96(sp)
    80003c8c:	eca6                	sd	s1,88(sp)
    80003c8e:	e8ca                	sd	s2,80(sp)
    80003c90:	e4ce                	sd	s3,72(sp)
    80003c92:	e0d2                	sd	s4,64(sp)
    80003c94:	fc56                	sd	s5,56(sp)
    80003c96:	f85a                	sd	s6,48(sp)
    80003c98:	f45e                	sd	s7,40(sp)
    80003c9a:	f062                	sd	s8,32(sp)
    80003c9c:	ec66                	sd	s9,24(sp)
    80003c9e:	e86a                	sd	s10,16(sp)
    80003ca0:	e46e                	sd	s11,8(sp)
    80003ca2:	1880                	addi	s0,sp,112
    80003ca4:	8b2a                	mv	s6,a0
    80003ca6:	8c2e                	mv	s8,a1
    80003ca8:	8ab2                	mv	s5,a2
    80003caa:	8936                	mv	s2,a3
    80003cac:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cae:	00e687bb          	addw	a5,a3,a4
    80003cb2:	0ed7e263          	bltu	a5,a3,80003d96 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cb6:	00043737          	lui	a4,0x43
    80003cba:	0ef76063          	bltu	a4,a5,80003d9a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cbe:	0c0b8863          	beqz	s7,80003d8e <writei+0x10e>
    80003cc2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cc8:	5cfd                	li	s9,-1
    80003cca:	a091                	j	80003d0e <writei+0x8e>
    80003ccc:	02099d93          	slli	s11,s3,0x20
    80003cd0:	020ddd93          	srli	s11,s11,0x20
    80003cd4:	05848513          	addi	a0,s1,88
    80003cd8:	86ee                	mv	a3,s11
    80003cda:	8656                	mv	a2,s5
    80003cdc:	85e2                	mv	a1,s8
    80003cde:	953a                	add	a0,a0,a4
    80003ce0:	ffffe097          	auipc	ra,0xffffe
    80003ce4:	384080e7          	jalr	900(ra) # 80002064 <either_copyin>
    80003ce8:	07950263          	beq	a0,s9,80003d4c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cec:	8526                	mv	a0,s1
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	790080e7          	jalr	1936(ra) # 8000447e <log_write>
    brelse(bp);
    80003cf6:	8526                	mv	a0,s1
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	50a080e7          	jalr	1290(ra) # 80003202 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d00:	01498a3b          	addw	s4,s3,s4
    80003d04:	0129893b          	addw	s2,s3,s2
    80003d08:	9aee                	add	s5,s5,s11
    80003d0a:	057a7663          	bgeu	s4,s7,80003d56 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d0e:	000b2483          	lw	s1,0(s6)
    80003d12:	00a9559b          	srliw	a1,s2,0xa
    80003d16:	855a                	mv	a0,s6
    80003d18:	fffff097          	auipc	ra,0xfffff
    80003d1c:	7ae080e7          	jalr	1966(ra) # 800034c6 <bmap>
    80003d20:	0005059b          	sext.w	a1,a0
    80003d24:	8526                	mv	a0,s1
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	3ac080e7          	jalr	940(ra) # 800030d2 <bread>
    80003d2e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d30:	3ff97713          	andi	a4,s2,1023
    80003d34:	40ed07bb          	subw	a5,s10,a4
    80003d38:	414b86bb          	subw	a3,s7,s4
    80003d3c:	89be                	mv	s3,a5
    80003d3e:	2781                	sext.w	a5,a5
    80003d40:	0006861b          	sext.w	a2,a3
    80003d44:	f8f674e3          	bgeu	a2,a5,80003ccc <writei+0x4c>
    80003d48:	89b6                	mv	s3,a3
    80003d4a:	b749                	j	80003ccc <writei+0x4c>
      brelse(bp);
    80003d4c:	8526                	mv	a0,s1
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	4b4080e7          	jalr	1204(ra) # 80003202 <brelse>
  }

  if(off > ip->size)
    80003d56:	04cb2783          	lw	a5,76(s6)
    80003d5a:	0127f463          	bgeu	a5,s2,80003d62 <writei+0xe2>
    ip->size = off;
    80003d5e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d62:	855a                	mv	a0,s6
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	aa6080e7          	jalr	-1370(ra) # 8000380a <iupdate>

  return tot;
    80003d6c:	000a051b          	sext.w	a0,s4
}
    80003d70:	70a6                	ld	ra,104(sp)
    80003d72:	7406                	ld	s0,96(sp)
    80003d74:	64e6                	ld	s1,88(sp)
    80003d76:	6946                	ld	s2,80(sp)
    80003d78:	69a6                	ld	s3,72(sp)
    80003d7a:	6a06                	ld	s4,64(sp)
    80003d7c:	7ae2                	ld	s5,56(sp)
    80003d7e:	7b42                	ld	s6,48(sp)
    80003d80:	7ba2                	ld	s7,40(sp)
    80003d82:	7c02                	ld	s8,32(sp)
    80003d84:	6ce2                	ld	s9,24(sp)
    80003d86:	6d42                	ld	s10,16(sp)
    80003d88:	6da2                	ld	s11,8(sp)
    80003d8a:	6165                	addi	sp,sp,112
    80003d8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d8e:	8a5e                	mv	s4,s7
    80003d90:	bfc9                	j	80003d62 <writei+0xe2>
    return -1;
    80003d92:	557d                	li	a0,-1
}
    80003d94:	8082                	ret
    return -1;
    80003d96:	557d                	li	a0,-1
    80003d98:	bfe1                	j	80003d70 <writei+0xf0>
    return -1;
    80003d9a:	557d                	li	a0,-1
    80003d9c:	bfd1                	j	80003d70 <writei+0xf0>

0000000080003d9e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d9e:	1141                	addi	sp,sp,-16
    80003da0:	e406                	sd	ra,8(sp)
    80003da2:	e022                	sd	s0,0(sp)
    80003da4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003da6:	4639                	li	a2,14
    80003da8:	ffffd097          	auipc	ra,0xffffd
    80003dac:	010080e7          	jalr	16(ra) # 80000db8 <strncmp>
}
    80003db0:	60a2                	ld	ra,8(sp)
    80003db2:	6402                	ld	s0,0(sp)
    80003db4:	0141                	addi	sp,sp,16
    80003db6:	8082                	ret

0000000080003db8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003db8:	7139                	addi	sp,sp,-64
    80003dba:	fc06                	sd	ra,56(sp)
    80003dbc:	f822                	sd	s0,48(sp)
    80003dbe:	f426                	sd	s1,40(sp)
    80003dc0:	f04a                	sd	s2,32(sp)
    80003dc2:	ec4e                	sd	s3,24(sp)
    80003dc4:	e852                	sd	s4,16(sp)
    80003dc6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dc8:	04451703          	lh	a4,68(a0)
    80003dcc:	4785                	li	a5,1
    80003dce:	00f71a63          	bne	a4,a5,80003de2 <dirlookup+0x2a>
    80003dd2:	892a                	mv	s2,a0
    80003dd4:	89ae                	mv	s3,a1
    80003dd6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd8:	457c                	lw	a5,76(a0)
    80003dda:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ddc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dde:	e79d                	bnez	a5,80003e0c <dirlookup+0x54>
    80003de0:	a8a5                	j	80003e58 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003de2:	00005517          	auipc	a0,0x5
    80003de6:	81650513          	addi	a0,a0,-2026 # 800085f8 <syscalls+0x1b0>
    80003dea:	ffffc097          	auipc	ra,0xffffc
    80003dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003df2:	00005517          	auipc	a0,0x5
    80003df6:	81e50513          	addi	a0,a0,-2018 # 80008610 <syscalls+0x1c8>
    80003dfa:	ffffc097          	auipc	ra,0xffffc
    80003dfe:	744080e7          	jalr	1860(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e02:	24c1                	addiw	s1,s1,16
    80003e04:	04c92783          	lw	a5,76(s2)
    80003e08:	04f4f763          	bgeu	s1,a5,80003e56 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0c:	4741                	li	a4,16
    80003e0e:	86a6                	mv	a3,s1
    80003e10:	fc040613          	addi	a2,s0,-64
    80003e14:	4581                	li	a1,0
    80003e16:	854a                	mv	a0,s2
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	d70080e7          	jalr	-656(ra) # 80003b88 <readi>
    80003e20:	47c1                	li	a5,16
    80003e22:	fcf518e3          	bne	a0,a5,80003df2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e26:	fc045783          	lhu	a5,-64(s0)
    80003e2a:	dfe1                	beqz	a5,80003e02 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e2c:	fc240593          	addi	a1,s0,-62
    80003e30:	854e                	mv	a0,s3
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	f6c080e7          	jalr	-148(ra) # 80003d9e <namecmp>
    80003e3a:	f561                	bnez	a0,80003e02 <dirlookup+0x4a>
      if(poff)
    80003e3c:	000a0463          	beqz	s4,80003e44 <dirlookup+0x8c>
        *poff = off;
    80003e40:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e44:	fc045583          	lhu	a1,-64(s0)
    80003e48:	00092503          	lw	a0,0(s2)
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	754080e7          	jalr	1876(ra) # 800035a0 <iget>
    80003e54:	a011                	j	80003e58 <dirlookup+0xa0>
  return 0;
    80003e56:	4501                	li	a0,0
}
    80003e58:	70e2                	ld	ra,56(sp)
    80003e5a:	7442                	ld	s0,48(sp)
    80003e5c:	74a2                	ld	s1,40(sp)
    80003e5e:	7902                	ld	s2,32(sp)
    80003e60:	69e2                	ld	s3,24(sp)
    80003e62:	6a42                	ld	s4,16(sp)
    80003e64:	6121                	addi	sp,sp,64
    80003e66:	8082                	ret

0000000080003e68 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e68:	711d                	addi	sp,sp,-96
    80003e6a:	ec86                	sd	ra,88(sp)
    80003e6c:	e8a2                	sd	s0,80(sp)
    80003e6e:	e4a6                	sd	s1,72(sp)
    80003e70:	e0ca                	sd	s2,64(sp)
    80003e72:	fc4e                	sd	s3,56(sp)
    80003e74:	f852                	sd	s4,48(sp)
    80003e76:	f456                	sd	s5,40(sp)
    80003e78:	f05a                	sd	s6,32(sp)
    80003e7a:	ec5e                	sd	s7,24(sp)
    80003e7c:	e862                	sd	s8,16(sp)
    80003e7e:	e466                	sd	s9,8(sp)
    80003e80:	1080                	addi	s0,sp,96
    80003e82:	84aa                	mv	s1,a0
    80003e84:	8b2e                	mv	s6,a1
    80003e86:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e88:	00054703          	lbu	a4,0(a0)
    80003e8c:	02f00793          	li	a5,47
    80003e90:	02f70363          	beq	a4,a5,80003eb6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e94:	ffffe097          	auipc	ra,0xffffe
    80003e98:	b2c080e7          	jalr	-1236(ra) # 800019c0 <myproc>
    80003e9c:	17853503          	ld	a0,376(a0)
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	9f6080e7          	jalr	-1546(ra) # 80003896 <idup>
    80003ea8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eaa:	02f00913          	li	s2,47
  len = path - s;
    80003eae:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003eb0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eb2:	4c05                	li	s8,1
    80003eb4:	a865                	j	80003f6c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003eb6:	4585                	li	a1,1
    80003eb8:	4505                	li	a0,1
    80003eba:	fffff097          	auipc	ra,0xfffff
    80003ebe:	6e6080e7          	jalr	1766(ra) # 800035a0 <iget>
    80003ec2:	89aa                	mv	s3,a0
    80003ec4:	b7dd                	j	80003eaa <namex+0x42>
      iunlockput(ip);
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	c6e080e7          	jalr	-914(ra) # 80003b36 <iunlockput>
      return 0;
    80003ed0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	60e6                	ld	ra,88(sp)
    80003ed6:	6446                	ld	s0,80(sp)
    80003ed8:	64a6                	ld	s1,72(sp)
    80003eda:	6906                	ld	s2,64(sp)
    80003edc:	79e2                	ld	s3,56(sp)
    80003ede:	7a42                	ld	s4,48(sp)
    80003ee0:	7aa2                	ld	s5,40(sp)
    80003ee2:	7b02                	ld	s6,32(sp)
    80003ee4:	6be2                	ld	s7,24(sp)
    80003ee6:	6c42                	ld	s8,16(sp)
    80003ee8:	6ca2                	ld	s9,8(sp)
    80003eea:	6125                	addi	sp,sp,96
    80003eec:	8082                	ret
      iunlock(ip);
    80003eee:	854e                	mv	a0,s3
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	aa6080e7          	jalr	-1370(ra) # 80003996 <iunlock>
      return ip;
    80003ef8:	bfe9                	j	80003ed2 <namex+0x6a>
      iunlockput(ip);
    80003efa:	854e                	mv	a0,s3
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	c3a080e7          	jalr	-966(ra) # 80003b36 <iunlockput>
      return 0;
    80003f04:	89d2                	mv	s3,s4
    80003f06:	b7f1                	j	80003ed2 <namex+0x6a>
  len = path - s;
    80003f08:	40b48633          	sub	a2,s1,a1
    80003f0c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f10:	094cd463          	bge	s9,s4,80003f98 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	8556                	mv	a0,s5
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	e28080e7          	jalr	-472(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f20:	0004c783          	lbu	a5,0(s1)
    80003f24:	01279763          	bne	a5,s2,80003f32 <namex+0xca>
    path++;
    80003f28:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	ff278de3          	beq	a5,s2,80003f28 <namex+0xc0>
    ilock(ip);
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	9a0080e7          	jalr	-1632(ra) # 800038d4 <ilock>
    if(ip->type != T_DIR){
    80003f3c:	04499783          	lh	a5,68(s3)
    80003f40:	f98793e3          	bne	a5,s8,80003ec6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f44:	000b0563          	beqz	s6,80003f4e <namex+0xe6>
    80003f48:	0004c783          	lbu	a5,0(s1)
    80003f4c:	d3cd                	beqz	a5,80003eee <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f4e:	865e                	mv	a2,s7
    80003f50:	85d6                	mv	a1,s5
    80003f52:	854e                	mv	a0,s3
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	e64080e7          	jalr	-412(ra) # 80003db8 <dirlookup>
    80003f5c:	8a2a                	mv	s4,a0
    80003f5e:	dd51                	beqz	a0,80003efa <namex+0x92>
    iunlockput(ip);
    80003f60:	854e                	mv	a0,s3
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	bd4080e7          	jalr	-1068(ra) # 80003b36 <iunlockput>
    ip = next;
    80003f6a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f6c:	0004c783          	lbu	a5,0(s1)
    80003f70:	05279763          	bne	a5,s2,80003fbe <namex+0x156>
    path++;
    80003f74:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f76:	0004c783          	lbu	a5,0(s1)
    80003f7a:	ff278de3          	beq	a5,s2,80003f74 <namex+0x10c>
  if(*path == 0)
    80003f7e:	c79d                	beqz	a5,80003fac <namex+0x144>
    path++;
    80003f80:	85a6                	mv	a1,s1
  len = path - s;
    80003f82:	8a5e                	mv	s4,s7
    80003f84:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f86:	01278963          	beq	a5,s2,80003f98 <namex+0x130>
    80003f8a:	dfbd                	beqz	a5,80003f08 <namex+0xa0>
    path++;
    80003f8c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f8e:	0004c783          	lbu	a5,0(s1)
    80003f92:	ff279ce3          	bne	a5,s2,80003f8a <namex+0x122>
    80003f96:	bf8d                	j	80003f08 <namex+0xa0>
    memmove(name, s, len);
    80003f98:	2601                	sext.w	a2,a2
    80003f9a:	8556                	mv	a0,s5
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	da4080e7          	jalr	-604(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003fa4:	9a56                	add	s4,s4,s5
    80003fa6:	000a0023          	sb	zero,0(s4)
    80003faa:	bf9d                	j	80003f20 <namex+0xb8>
  if(nameiparent){
    80003fac:	f20b03e3          	beqz	s6,80003ed2 <namex+0x6a>
    iput(ip);
    80003fb0:	854e                	mv	a0,s3
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	adc080e7          	jalr	-1316(ra) # 80003a8e <iput>
    return 0;
    80003fba:	4981                	li	s3,0
    80003fbc:	bf19                	j	80003ed2 <namex+0x6a>
  if(*path == 0)
    80003fbe:	d7fd                	beqz	a5,80003fac <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fc0:	0004c783          	lbu	a5,0(s1)
    80003fc4:	85a6                	mv	a1,s1
    80003fc6:	b7d1                	j	80003f8a <namex+0x122>

0000000080003fc8 <dirlink>:
{
    80003fc8:	7139                	addi	sp,sp,-64
    80003fca:	fc06                	sd	ra,56(sp)
    80003fcc:	f822                	sd	s0,48(sp)
    80003fce:	f426                	sd	s1,40(sp)
    80003fd0:	f04a                	sd	s2,32(sp)
    80003fd2:	ec4e                	sd	s3,24(sp)
    80003fd4:	e852                	sd	s4,16(sp)
    80003fd6:	0080                	addi	s0,sp,64
    80003fd8:	892a                	mv	s2,a0
    80003fda:	8a2e                	mv	s4,a1
    80003fdc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fde:	4601                	li	a2,0
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	dd8080e7          	jalr	-552(ra) # 80003db8 <dirlookup>
    80003fe8:	e93d                	bnez	a0,8000405e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fea:	04c92483          	lw	s1,76(s2)
    80003fee:	c49d                	beqz	s1,8000401c <dirlink+0x54>
    80003ff0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff2:	4741                	li	a4,16
    80003ff4:	86a6                	mv	a3,s1
    80003ff6:	fc040613          	addi	a2,s0,-64
    80003ffa:	4581                	li	a1,0
    80003ffc:	854a                	mv	a0,s2
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	b8a080e7          	jalr	-1142(ra) # 80003b88 <readi>
    80004006:	47c1                	li	a5,16
    80004008:	06f51163          	bne	a0,a5,8000406a <dirlink+0xa2>
    if(de.inum == 0)
    8000400c:	fc045783          	lhu	a5,-64(s0)
    80004010:	c791                	beqz	a5,8000401c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004012:	24c1                	addiw	s1,s1,16
    80004014:	04c92783          	lw	a5,76(s2)
    80004018:	fcf4ede3          	bltu	s1,a5,80003ff2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000401c:	4639                	li	a2,14
    8000401e:	85d2                	mv	a1,s4
    80004020:	fc240513          	addi	a0,s0,-62
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	dd0080e7          	jalr	-560(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000402c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004030:	4741                	li	a4,16
    80004032:	86a6                	mv	a3,s1
    80004034:	fc040613          	addi	a2,s0,-64
    80004038:	4581                	li	a1,0
    8000403a:	854a                	mv	a0,s2
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	c44080e7          	jalr	-956(ra) # 80003c80 <writei>
    80004044:	872a                	mv	a4,a0
    80004046:	47c1                	li	a5,16
  return 0;
    80004048:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404a:	02f71863          	bne	a4,a5,8000407a <dirlink+0xb2>
}
    8000404e:	70e2                	ld	ra,56(sp)
    80004050:	7442                	ld	s0,48(sp)
    80004052:	74a2                	ld	s1,40(sp)
    80004054:	7902                	ld	s2,32(sp)
    80004056:	69e2                	ld	s3,24(sp)
    80004058:	6a42                	ld	s4,16(sp)
    8000405a:	6121                	addi	sp,sp,64
    8000405c:	8082                	ret
    iput(ip);
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	a30080e7          	jalr	-1488(ra) # 80003a8e <iput>
    return -1;
    80004066:	557d                	li	a0,-1
    80004068:	b7dd                	j	8000404e <dirlink+0x86>
      panic("dirlink read");
    8000406a:	00004517          	auipc	a0,0x4
    8000406e:	5b650513          	addi	a0,a0,1462 # 80008620 <syscalls+0x1d8>
    80004072:	ffffc097          	auipc	ra,0xffffc
    80004076:	4cc080e7          	jalr	1228(ra) # 8000053e <panic>
    panic("dirlink");
    8000407a:	00004517          	auipc	a0,0x4
    8000407e:	6b650513          	addi	a0,a0,1718 # 80008730 <syscalls+0x2e8>
    80004082:	ffffc097          	auipc	ra,0xffffc
    80004086:	4bc080e7          	jalr	1212(ra) # 8000053e <panic>

000000008000408a <namei>:

struct inode*
namei(char *path)
{
    8000408a:	1101                	addi	sp,sp,-32
    8000408c:	ec06                	sd	ra,24(sp)
    8000408e:	e822                	sd	s0,16(sp)
    80004090:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004092:	fe040613          	addi	a2,s0,-32
    80004096:	4581                	li	a1,0
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	dd0080e7          	jalr	-560(ra) # 80003e68 <namex>
}
    800040a0:	60e2                	ld	ra,24(sp)
    800040a2:	6442                	ld	s0,16(sp)
    800040a4:	6105                	addi	sp,sp,32
    800040a6:	8082                	ret

00000000800040a8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040a8:	1141                	addi	sp,sp,-16
    800040aa:	e406                	sd	ra,8(sp)
    800040ac:	e022                	sd	s0,0(sp)
    800040ae:	0800                	addi	s0,sp,16
    800040b0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040b2:	4585                	li	a1,1
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	db4080e7          	jalr	-588(ra) # 80003e68 <namex>
}
    800040bc:	60a2                	ld	ra,8(sp)
    800040be:	6402                	ld	s0,0(sp)
    800040c0:	0141                	addi	sp,sp,16
    800040c2:	8082                	ret

00000000800040c4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040c4:	1101                	addi	sp,sp,-32
    800040c6:	ec06                	sd	ra,24(sp)
    800040c8:	e822                	sd	s0,16(sp)
    800040ca:	e426                	sd	s1,8(sp)
    800040cc:	e04a                	sd	s2,0(sp)
    800040ce:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040d0:	0001e917          	auipc	s2,0x1e
    800040d4:	bc090913          	addi	s2,s2,-1088 # 80021c90 <log>
    800040d8:	01892583          	lw	a1,24(s2)
    800040dc:	02892503          	lw	a0,40(s2)
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	ff2080e7          	jalr	-14(ra) # 800030d2 <bread>
    800040e8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040ea:	02c92683          	lw	a3,44(s2)
    800040ee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040f0:	02d05763          	blez	a3,8000411e <write_head+0x5a>
    800040f4:	0001e797          	auipc	a5,0x1e
    800040f8:	bcc78793          	addi	a5,a5,-1076 # 80021cc0 <log+0x30>
    800040fc:	05c50713          	addi	a4,a0,92
    80004100:	36fd                	addiw	a3,a3,-1
    80004102:	1682                	slli	a3,a3,0x20
    80004104:	9281                	srli	a3,a3,0x20
    80004106:	068a                	slli	a3,a3,0x2
    80004108:	0001e617          	auipc	a2,0x1e
    8000410c:	bbc60613          	addi	a2,a2,-1092 # 80021cc4 <log+0x34>
    80004110:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004112:	4390                	lw	a2,0(a5)
    80004114:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004116:	0791                	addi	a5,a5,4
    80004118:	0711                	addi	a4,a4,4
    8000411a:	fed79ce3          	bne	a5,a3,80004112 <write_head+0x4e>
  }
  bwrite(buf);
    8000411e:	8526                	mv	a0,s1
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	0a4080e7          	jalr	164(ra) # 800031c4 <bwrite>
  brelse(buf);
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	0d8080e7          	jalr	216(ra) # 80003202 <brelse>
}
    80004132:	60e2                	ld	ra,24(sp)
    80004134:	6442                	ld	s0,16(sp)
    80004136:	64a2                	ld	s1,8(sp)
    80004138:	6902                	ld	s2,0(sp)
    8000413a:	6105                	addi	sp,sp,32
    8000413c:	8082                	ret

000000008000413e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413e:	0001e797          	auipc	a5,0x1e
    80004142:	b7e7a783          	lw	a5,-1154(a5) # 80021cbc <log+0x2c>
    80004146:	0af05d63          	blez	a5,80004200 <install_trans+0xc2>
{
    8000414a:	7139                	addi	sp,sp,-64
    8000414c:	fc06                	sd	ra,56(sp)
    8000414e:	f822                	sd	s0,48(sp)
    80004150:	f426                	sd	s1,40(sp)
    80004152:	f04a                	sd	s2,32(sp)
    80004154:	ec4e                	sd	s3,24(sp)
    80004156:	e852                	sd	s4,16(sp)
    80004158:	e456                	sd	s5,8(sp)
    8000415a:	e05a                	sd	s6,0(sp)
    8000415c:	0080                	addi	s0,sp,64
    8000415e:	8b2a                	mv	s6,a0
    80004160:	0001ea97          	auipc	s5,0x1e
    80004164:	b60a8a93          	addi	s5,s5,-1184 # 80021cc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004168:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000416a:	0001e997          	auipc	s3,0x1e
    8000416e:	b2698993          	addi	s3,s3,-1242 # 80021c90 <log>
    80004172:	a035                	j	8000419e <install_trans+0x60>
      bunpin(dbuf);
    80004174:	8526                	mv	a0,s1
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	166080e7          	jalr	358(ra) # 800032dc <bunpin>
    brelse(lbuf);
    8000417e:	854a                	mv	a0,s2
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	082080e7          	jalr	130(ra) # 80003202 <brelse>
    brelse(dbuf);
    80004188:	8526                	mv	a0,s1
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	078080e7          	jalr	120(ra) # 80003202 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004192:	2a05                	addiw	s4,s4,1
    80004194:	0a91                	addi	s5,s5,4
    80004196:	02c9a783          	lw	a5,44(s3)
    8000419a:	04fa5963          	bge	s4,a5,800041ec <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000419e:	0189a583          	lw	a1,24(s3)
    800041a2:	014585bb          	addw	a1,a1,s4
    800041a6:	2585                	addiw	a1,a1,1
    800041a8:	0289a503          	lw	a0,40(s3)
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	f26080e7          	jalr	-218(ra) # 800030d2 <bread>
    800041b4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041b6:	000aa583          	lw	a1,0(s5)
    800041ba:	0289a503          	lw	a0,40(s3)
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	f14080e7          	jalr	-236(ra) # 800030d2 <bread>
    800041c6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041c8:	40000613          	li	a2,1024
    800041cc:	05890593          	addi	a1,s2,88
    800041d0:	05850513          	addi	a0,a0,88
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	b6c080e7          	jalr	-1172(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041dc:	8526                	mv	a0,s1
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	fe6080e7          	jalr	-26(ra) # 800031c4 <bwrite>
    if(recovering == 0)
    800041e6:	f80b1ce3          	bnez	s6,8000417e <install_trans+0x40>
    800041ea:	b769                	j	80004174 <install_trans+0x36>
}
    800041ec:	70e2                	ld	ra,56(sp)
    800041ee:	7442                	ld	s0,48(sp)
    800041f0:	74a2                	ld	s1,40(sp)
    800041f2:	7902                	ld	s2,32(sp)
    800041f4:	69e2                	ld	s3,24(sp)
    800041f6:	6a42                	ld	s4,16(sp)
    800041f8:	6aa2                	ld	s5,8(sp)
    800041fa:	6b02                	ld	s6,0(sp)
    800041fc:	6121                	addi	sp,sp,64
    800041fe:	8082                	ret
    80004200:	8082                	ret

0000000080004202 <initlog>:
{
    80004202:	7179                	addi	sp,sp,-48
    80004204:	f406                	sd	ra,40(sp)
    80004206:	f022                	sd	s0,32(sp)
    80004208:	ec26                	sd	s1,24(sp)
    8000420a:	e84a                	sd	s2,16(sp)
    8000420c:	e44e                	sd	s3,8(sp)
    8000420e:	1800                	addi	s0,sp,48
    80004210:	892a                	mv	s2,a0
    80004212:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004214:	0001e497          	auipc	s1,0x1e
    80004218:	a7c48493          	addi	s1,s1,-1412 # 80021c90 <log>
    8000421c:	00004597          	auipc	a1,0x4
    80004220:	41458593          	addi	a1,a1,1044 # 80008630 <syscalls+0x1e8>
    80004224:	8526                	mv	a0,s1
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	92e080e7          	jalr	-1746(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000422e:	0149a583          	lw	a1,20(s3)
    80004232:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004234:	0109a783          	lw	a5,16(s3)
    80004238:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000423a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000423e:	854a                	mv	a0,s2
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	e92080e7          	jalr	-366(ra) # 800030d2 <bread>
  log.lh.n = lh->n;
    80004248:	4d3c                	lw	a5,88(a0)
    8000424a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000424c:	02f05563          	blez	a5,80004276 <initlog+0x74>
    80004250:	05c50713          	addi	a4,a0,92
    80004254:	0001e697          	auipc	a3,0x1e
    80004258:	a6c68693          	addi	a3,a3,-1428 # 80021cc0 <log+0x30>
    8000425c:	37fd                	addiw	a5,a5,-1
    8000425e:	1782                	slli	a5,a5,0x20
    80004260:	9381                	srli	a5,a5,0x20
    80004262:	078a                	slli	a5,a5,0x2
    80004264:	06050613          	addi	a2,a0,96
    80004268:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000426a:	4310                	lw	a2,0(a4)
    8000426c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000426e:	0711                	addi	a4,a4,4
    80004270:	0691                	addi	a3,a3,4
    80004272:	fef71ce3          	bne	a4,a5,8000426a <initlog+0x68>
  brelse(buf);
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	f8c080e7          	jalr	-116(ra) # 80003202 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000427e:	4505                	li	a0,1
    80004280:	00000097          	auipc	ra,0x0
    80004284:	ebe080e7          	jalr	-322(ra) # 8000413e <install_trans>
  log.lh.n = 0;
    80004288:	0001e797          	auipc	a5,0x1e
    8000428c:	a207aa23          	sw	zero,-1484(a5) # 80021cbc <log+0x2c>
  write_head(); // clear the log
    80004290:	00000097          	auipc	ra,0x0
    80004294:	e34080e7          	jalr	-460(ra) # 800040c4 <write_head>
}
    80004298:	70a2                	ld	ra,40(sp)
    8000429a:	7402                	ld	s0,32(sp)
    8000429c:	64e2                	ld	s1,24(sp)
    8000429e:	6942                	ld	s2,16(sp)
    800042a0:	69a2                	ld	s3,8(sp)
    800042a2:	6145                	addi	sp,sp,48
    800042a4:	8082                	ret

00000000800042a6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042a6:	1101                	addi	sp,sp,-32
    800042a8:	ec06                	sd	ra,24(sp)
    800042aa:	e822                	sd	s0,16(sp)
    800042ac:	e426                	sd	s1,8(sp)
    800042ae:	e04a                	sd	s2,0(sp)
    800042b0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042b2:	0001e517          	auipc	a0,0x1e
    800042b6:	9de50513          	addi	a0,a0,-1570 # 80021c90 <log>
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	92a080e7          	jalr	-1750(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042c2:	0001e497          	auipc	s1,0x1e
    800042c6:	9ce48493          	addi	s1,s1,-1586 # 80021c90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ca:	4979                	li	s2,30
    800042cc:	a039                	j	800042da <begin_op+0x34>
      sleep(&log, &log.lock);
    800042ce:	85a6                	mv	a1,s1
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffe097          	auipc	ra,0xffffe
    800042d6:	042080e7          	jalr	66(ra) # 80002314 <sleep>
    if(log.committing){
    800042da:	50dc                	lw	a5,36(s1)
    800042dc:	fbed                	bnez	a5,800042ce <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042de:	509c                	lw	a5,32(s1)
    800042e0:	0017871b          	addiw	a4,a5,1
    800042e4:	0007069b          	sext.w	a3,a4
    800042e8:	0027179b          	slliw	a5,a4,0x2
    800042ec:	9fb9                	addw	a5,a5,a4
    800042ee:	0017979b          	slliw	a5,a5,0x1
    800042f2:	54d8                	lw	a4,44(s1)
    800042f4:	9fb9                	addw	a5,a5,a4
    800042f6:	00f95963          	bge	s2,a5,80004308 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042fa:	85a6                	mv	a1,s1
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffe097          	auipc	ra,0xffffe
    80004302:	016080e7          	jalr	22(ra) # 80002314 <sleep>
    80004306:	bfd1                	j	800042da <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004308:	0001e517          	auipc	a0,0x1e
    8000430c:	98850513          	addi	a0,a0,-1656 # 80021c90 <log>
    80004310:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	986080e7          	jalr	-1658(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000431a:	60e2                	ld	ra,24(sp)
    8000431c:	6442                	ld	s0,16(sp)
    8000431e:	64a2                	ld	s1,8(sp)
    80004320:	6902                	ld	s2,0(sp)
    80004322:	6105                	addi	sp,sp,32
    80004324:	8082                	ret

0000000080004326 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004326:	7139                	addi	sp,sp,-64
    80004328:	fc06                	sd	ra,56(sp)
    8000432a:	f822                	sd	s0,48(sp)
    8000432c:	f426                	sd	s1,40(sp)
    8000432e:	f04a                	sd	s2,32(sp)
    80004330:	ec4e                	sd	s3,24(sp)
    80004332:	e852                	sd	s4,16(sp)
    80004334:	e456                	sd	s5,8(sp)
    80004336:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004338:	0001e497          	auipc	s1,0x1e
    8000433c:	95848493          	addi	s1,s1,-1704 # 80021c90 <log>
    80004340:	8526                	mv	a0,s1
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	8a2080e7          	jalr	-1886(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000434a:	509c                	lw	a5,32(s1)
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	0007891b          	sext.w	s2,a5
    80004352:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004354:	50dc                	lw	a5,36(s1)
    80004356:	efb9                	bnez	a5,800043b4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004358:	06091663          	bnez	s2,800043c4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000435c:	0001e497          	auipc	s1,0x1e
    80004360:	93448493          	addi	s1,s1,-1740 # 80021c90 <log>
    80004364:	4785                	li	a5,1
    80004366:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004368:	8526                	mv	a0,s1
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	92e080e7          	jalr	-1746(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004372:	54dc                	lw	a5,44(s1)
    80004374:	06f04763          	bgtz	a5,800043e2 <end_op+0xbc>
    acquire(&log.lock);
    80004378:	0001e497          	auipc	s1,0x1e
    8000437c:	91848493          	addi	s1,s1,-1768 # 80021c90 <log>
    80004380:	8526                	mv	a0,s1
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	862080e7          	jalr	-1950(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000438a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000438e:	8526                	mv	a0,s1
    80004390:	ffffe097          	auipc	ra,0xffffe
    80004394:	11c080e7          	jalr	284(ra) # 800024ac <wakeup>
    release(&log.lock);
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8fe080e7          	jalr	-1794(ra) # 80000c98 <release>
}
    800043a2:	70e2                	ld	ra,56(sp)
    800043a4:	7442                	ld	s0,48(sp)
    800043a6:	74a2                	ld	s1,40(sp)
    800043a8:	7902                	ld	s2,32(sp)
    800043aa:	69e2                	ld	s3,24(sp)
    800043ac:	6a42                	ld	s4,16(sp)
    800043ae:	6aa2                	ld	s5,8(sp)
    800043b0:	6121                	addi	sp,sp,64
    800043b2:	8082                	ret
    panic("log.committing");
    800043b4:	00004517          	auipc	a0,0x4
    800043b8:	28450513          	addi	a0,a0,644 # 80008638 <syscalls+0x1f0>
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	182080e7          	jalr	386(ra) # 8000053e <panic>
    wakeup(&log);
    800043c4:	0001e497          	auipc	s1,0x1e
    800043c8:	8cc48493          	addi	s1,s1,-1844 # 80021c90 <log>
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffe097          	auipc	ra,0xffffe
    800043d2:	0de080e7          	jalr	222(ra) # 800024ac <wakeup>
  release(&log.lock);
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
  if(do_commit){
    800043e0:	b7c9                	j	800043a2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e2:	0001ea97          	auipc	s5,0x1e
    800043e6:	8dea8a93          	addi	s5,s5,-1826 # 80021cc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043ea:	0001ea17          	auipc	s4,0x1e
    800043ee:	8a6a0a13          	addi	s4,s4,-1882 # 80021c90 <log>
    800043f2:	018a2583          	lw	a1,24(s4)
    800043f6:	012585bb          	addw	a1,a1,s2
    800043fa:	2585                	addiw	a1,a1,1
    800043fc:	028a2503          	lw	a0,40(s4)
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	cd2080e7          	jalr	-814(ra) # 800030d2 <bread>
    80004408:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000440a:	000aa583          	lw	a1,0(s5)
    8000440e:	028a2503          	lw	a0,40(s4)
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	cc0080e7          	jalr	-832(ra) # 800030d2 <bread>
    8000441a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000441c:	40000613          	li	a2,1024
    80004420:	05850593          	addi	a1,a0,88
    80004424:	05848513          	addi	a0,s1,88
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	918080e7          	jalr	-1768(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	d92080e7          	jalr	-622(ra) # 800031c4 <bwrite>
    brelse(from);
    8000443a:	854e                	mv	a0,s3
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	dc6080e7          	jalr	-570(ra) # 80003202 <brelse>
    brelse(to);
    80004444:	8526                	mv	a0,s1
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	dbc080e7          	jalr	-580(ra) # 80003202 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444e:	2905                	addiw	s2,s2,1
    80004450:	0a91                	addi	s5,s5,4
    80004452:	02ca2783          	lw	a5,44(s4)
    80004456:	f8f94ee3          	blt	s2,a5,800043f2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	c6a080e7          	jalr	-918(ra) # 800040c4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004462:	4501                	li	a0,0
    80004464:	00000097          	auipc	ra,0x0
    80004468:	cda080e7          	jalr	-806(ra) # 8000413e <install_trans>
    log.lh.n = 0;
    8000446c:	0001e797          	auipc	a5,0x1e
    80004470:	8407a823          	sw	zero,-1968(a5) # 80021cbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c50080e7          	jalr	-944(ra) # 800040c4 <write_head>
    8000447c:	bdf5                	j	80004378 <end_op+0x52>

000000008000447e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000447e:	1101                	addi	sp,sp,-32
    80004480:	ec06                	sd	ra,24(sp)
    80004482:	e822                	sd	s0,16(sp)
    80004484:	e426                	sd	s1,8(sp)
    80004486:	e04a                	sd	s2,0(sp)
    80004488:	1000                	addi	s0,sp,32
    8000448a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000448c:	0001e917          	auipc	s2,0x1e
    80004490:	80490913          	addi	s2,s2,-2044 # 80021c90 <log>
    80004494:	854a                	mv	a0,s2
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	74e080e7          	jalr	1870(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000449e:	02c92603          	lw	a2,44(s2)
    800044a2:	47f5                	li	a5,29
    800044a4:	06c7c563          	blt	a5,a2,8000450e <log_write+0x90>
    800044a8:	0001e797          	auipc	a5,0x1e
    800044ac:	8047a783          	lw	a5,-2044(a5) # 80021cac <log+0x1c>
    800044b0:	37fd                	addiw	a5,a5,-1
    800044b2:	04f65e63          	bge	a2,a5,8000450e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044b6:	0001d797          	auipc	a5,0x1d
    800044ba:	7fa7a783          	lw	a5,2042(a5) # 80021cb0 <log+0x20>
    800044be:	06f05063          	blez	a5,8000451e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044c2:	4781                	li	a5,0
    800044c4:	06c05563          	blez	a2,8000452e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c8:	44cc                	lw	a1,12(s1)
    800044ca:	0001d717          	auipc	a4,0x1d
    800044ce:	7f670713          	addi	a4,a4,2038 # 80021cc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044d2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044d4:	4314                	lw	a3,0(a4)
    800044d6:	04b68c63          	beq	a3,a1,8000452e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044da:	2785                	addiw	a5,a5,1
    800044dc:	0711                	addi	a4,a4,4
    800044de:	fef61be3          	bne	a2,a5,800044d4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044e2:	0621                	addi	a2,a2,8
    800044e4:	060a                	slli	a2,a2,0x2
    800044e6:	0001d797          	auipc	a5,0x1d
    800044ea:	7aa78793          	addi	a5,a5,1962 # 80021c90 <log>
    800044ee:	963e                	add	a2,a2,a5
    800044f0:	44dc                	lw	a5,12(s1)
    800044f2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044f4:	8526                	mv	a0,s1
    800044f6:	fffff097          	auipc	ra,0xfffff
    800044fa:	daa080e7          	jalr	-598(ra) # 800032a0 <bpin>
    log.lh.n++;
    800044fe:	0001d717          	auipc	a4,0x1d
    80004502:	79270713          	addi	a4,a4,1938 # 80021c90 <log>
    80004506:	575c                	lw	a5,44(a4)
    80004508:	2785                	addiw	a5,a5,1
    8000450a:	d75c                	sw	a5,44(a4)
    8000450c:	a835                	j	80004548 <log_write+0xca>
    panic("too big a transaction");
    8000450e:	00004517          	auipc	a0,0x4
    80004512:	13a50513          	addi	a0,a0,314 # 80008648 <syscalls+0x200>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	028080e7          	jalr	40(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000451e:	00004517          	auipc	a0,0x4
    80004522:	14250513          	addi	a0,a0,322 # 80008660 <syscalls+0x218>
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	018080e7          	jalr	24(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000452e:	00878713          	addi	a4,a5,8
    80004532:	00271693          	slli	a3,a4,0x2
    80004536:	0001d717          	auipc	a4,0x1d
    8000453a:	75a70713          	addi	a4,a4,1882 # 80021c90 <log>
    8000453e:	9736                	add	a4,a4,a3
    80004540:	44d4                	lw	a3,12(s1)
    80004542:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004544:	faf608e3          	beq	a2,a5,800044f4 <log_write+0x76>
  }
  release(&log.lock);
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	74850513          	addi	a0,a0,1864 # 80021c90 <log>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	748080e7          	jalr	1864(ra) # 80000c98 <release>
}
    80004558:	60e2                	ld	ra,24(sp)
    8000455a:	6442                	ld	s0,16(sp)
    8000455c:	64a2                	ld	s1,8(sp)
    8000455e:	6902                	ld	s2,0(sp)
    80004560:	6105                	addi	sp,sp,32
    80004562:	8082                	ret

0000000080004564 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	e426                	sd	s1,8(sp)
    8000456c:	e04a                	sd	s2,0(sp)
    8000456e:	1000                	addi	s0,sp,32
    80004570:	84aa                	mv	s1,a0
    80004572:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004574:	00004597          	auipc	a1,0x4
    80004578:	10c58593          	addi	a1,a1,268 # 80008680 <syscalls+0x238>
    8000457c:	0521                	addi	a0,a0,8
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	5d6080e7          	jalr	1494(ra) # 80000b54 <initlock>
  lk->name = name;
    80004586:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000458a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000458e:	0204a423          	sw	zero,40(s1)
}
    80004592:	60e2                	ld	ra,24(sp)
    80004594:	6442                	ld	s0,16(sp)
    80004596:	64a2                	ld	s1,8(sp)
    80004598:	6902                	ld	s2,0(sp)
    8000459a:	6105                	addi	sp,sp,32
    8000459c:	8082                	ret

000000008000459e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	e04a                	sd	s2,0(sp)
    800045a8:	1000                	addi	s0,sp,32
    800045aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ac:	00850913          	addi	s2,a0,8
    800045b0:	854a                	mv	a0,s2
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	632080e7          	jalr	1586(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045ba:	409c                	lw	a5,0(s1)
    800045bc:	cb89                	beqz	a5,800045ce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045be:	85ca                	mv	a1,s2
    800045c0:	8526                	mv	a0,s1
    800045c2:	ffffe097          	auipc	ra,0xffffe
    800045c6:	d52080e7          	jalr	-686(ra) # 80002314 <sleep>
  while (lk->locked) {
    800045ca:	409c                	lw	a5,0(s1)
    800045cc:	fbed                	bnez	a5,800045be <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ce:	4785                	li	a5,1
    800045d0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045d2:	ffffd097          	auipc	ra,0xffffd
    800045d6:	3ee080e7          	jalr	1006(ra) # 800019c0 <myproc>
    800045da:	591c                	lw	a5,48(a0)
    800045dc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
}
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6902                	ld	s2,0(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045f4:	1101                	addi	sp,sp,-32
    800045f6:	ec06                	sd	ra,24(sp)
    800045f8:	e822                	sd	s0,16(sp)
    800045fa:	e426                	sd	s1,8(sp)
    800045fc:	e04a                	sd	s2,0(sp)
    800045fe:	1000                	addi	s0,sp,32
    80004600:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004602:	00850913          	addi	s2,a0,8
    80004606:	854a                	mv	a0,s2
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	5dc080e7          	jalr	1500(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004610:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004614:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004618:	8526                	mv	a0,s1
    8000461a:	ffffe097          	auipc	ra,0xffffe
    8000461e:	e92080e7          	jalr	-366(ra) # 800024ac <wakeup>
  release(&lk->lk);
    80004622:	854a                	mv	a0,s2
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	674080e7          	jalr	1652(ra) # 80000c98 <release>
}
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6902                	ld	s2,0(sp)
    80004634:	6105                	addi	sp,sp,32
    80004636:	8082                	ret

0000000080004638 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004638:	7179                	addi	sp,sp,-48
    8000463a:	f406                	sd	ra,40(sp)
    8000463c:	f022                	sd	s0,32(sp)
    8000463e:	ec26                	sd	s1,24(sp)
    80004640:	e84a                	sd	s2,16(sp)
    80004642:	e44e                	sd	s3,8(sp)
    80004644:	1800                	addi	s0,sp,48
    80004646:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004648:	00850913          	addi	s2,a0,8
    8000464c:	854a                	mv	a0,s2
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004656:	409c                	lw	a5,0(s1)
    80004658:	ef99                	bnez	a5,80004676 <holdingsleep+0x3e>
    8000465a:	4481                	li	s1,0
  release(&lk->lk);
    8000465c:	854a                	mv	a0,s2
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	63a080e7          	jalr	1594(ra) # 80000c98 <release>
  return r;
}
    80004666:	8526                	mv	a0,s1
    80004668:	70a2                	ld	ra,40(sp)
    8000466a:	7402                	ld	s0,32(sp)
    8000466c:	64e2                	ld	s1,24(sp)
    8000466e:	6942                	ld	s2,16(sp)
    80004670:	69a2                	ld	s3,8(sp)
    80004672:	6145                	addi	sp,sp,48
    80004674:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004676:	0284a983          	lw	s3,40(s1)
    8000467a:	ffffd097          	auipc	ra,0xffffd
    8000467e:	346080e7          	jalr	838(ra) # 800019c0 <myproc>
    80004682:	5904                	lw	s1,48(a0)
    80004684:	413484b3          	sub	s1,s1,s3
    80004688:	0014b493          	seqz	s1,s1
    8000468c:	bfc1                	j	8000465c <holdingsleep+0x24>

000000008000468e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000468e:	1141                	addi	sp,sp,-16
    80004690:	e406                	sd	ra,8(sp)
    80004692:	e022                	sd	s0,0(sp)
    80004694:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004696:	00004597          	auipc	a1,0x4
    8000469a:	ffa58593          	addi	a1,a1,-6 # 80008690 <syscalls+0x248>
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	73a50513          	addi	a0,a0,1850 # 80021dd8 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	4ae080e7          	jalr	1198(ra) # 80000b54 <initlock>
}
    800046ae:	60a2                	ld	ra,8(sp)
    800046b0:	6402                	ld	s0,0(sp)
    800046b2:	0141                	addi	sp,sp,16
    800046b4:	8082                	ret

00000000800046b6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	e426                	sd	s1,8(sp)
    800046be:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	71850513          	addi	a0,a0,1816 # 80021dd8 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	51c080e7          	jalr	1308(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d0:	0001d497          	auipc	s1,0x1d
    800046d4:	72048493          	addi	s1,s1,1824 # 80021df0 <ftable+0x18>
    800046d8:	0001e717          	auipc	a4,0x1e
    800046dc:	6b870713          	addi	a4,a4,1720 # 80022d90 <ftable+0xfb8>
    if(f->ref == 0){
    800046e0:	40dc                	lw	a5,4(s1)
    800046e2:	cf99                	beqz	a5,80004700 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046e4:	02848493          	addi	s1,s1,40
    800046e8:	fee49ce3          	bne	s1,a4,800046e0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046ec:	0001d517          	auipc	a0,0x1d
    800046f0:	6ec50513          	addi	a0,a0,1772 # 80021dd8 <ftable>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
  return 0;
    800046fc:	4481                	li	s1,0
    800046fe:	a819                	j	80004714 <filealloc+0x5e>
      f->ref = 1;
    80004700:	4785                	li	a5,1
    80004702:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004704:	0001d517          	auipc	a0,0x1d
    80004708:	6d450513          	addi	a0,a0,1748 # 80021dd8 <ftable>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	58c080e7          	jalr	1420(ra) # 80000c98 <release>
}
    80004714:	8526                	mv	a0,s1
    80004716:	60e2                	ld	ra,24(sp)
    80004718:	6442                	ld	s0,16(sp)
    8000471a:	64a2                	ld	s1,8(sp)
    8000471c:	6105                	addi	sp,sp,32
    8000471e:	8082                	ret

0000000080004720 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004720:	1101                	addi	sp,sp,-32
    80004722:	ec06                	sd	ra,24(sp)
    80004724:	e822                	sd	s0,16(sp)
    80004726:	e426                	sd	s1,8(sp)
    80004728:	1000                	addi	s0,sp,32
    8000472a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000472c:	0001d517          	auipc	a0,0x1d
    80004730:	6ac50513          	addi	a0,a0,1708 # 80021dd8 <ftable>
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	4b0080e7          	jalr	1200(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000473c:	40dc                	lw	a5,4(s1)
    8000473e:	02f05263          	blez	a5,80004762 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004742:	2785                	addiw	a5,a5,1
    80004744:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004746:	0001d517          	auipc	a0,0x1d
    8000474a:	69250513          	addi	a0,a0,1682 # 80021dd8 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	54a080e7          	jalr	1354(ra) # 80000c98 <release>
  return f;
}
    80004756:	8526                	mv	a0,s1
    80004758:	60e2                	ld	ra,24(sp)
    8000475a:	6442                	ld	s0,16(sp)
    8000475c:	64a2                	ld	s1,8(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret
    panic("filedup");
    80004762:	00004517          	auipc	a0,0x4
    80004766:	f3650513          	addi	a0,a0,-202 # 80008698 <syscalls+0x250>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>

0000000080004772 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004772:	7139                	addi	sp,sp,-64
    80004774:	fc06                	sd	ra,56(sp)
    80004776:	f822                	sd	s0,48(sp)
    80004778:	f426                	sd	s1,40(sp)
    8000477a:	f04a                	sd	s2,32(sp)
    8000477c:	ec4e                	sd	s3,24(sp)
    8000477e:	e852                	sd	s4,16(sp)
    80004780:	e456                	sd	s5,8(sp)
    80004782:	0080                	addi	s0,sp,64
    80004784:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004786:	0001d517          	auipc	a0,0x1d
    8000478a:	65250513          	addi	a0,a0,1618 # 80021dd8 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	456080e7          	jalr	1110(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004796:	40dc                	lw	a5,4(s1)
    80004798:	06f05163          	blez	a5,800047fa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000479c:	37fd                	addiw	a5,a5,-1
    8000479e:	0007871b          	sext.w	a4,a5
    800047a2:	c0dc                	sw	a5,4(s1)
    800047a4:	06e04363          	bgtz	a4,8000480a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047a8:	0004a903          	lw	s2,0(s1)
    800047ac:	0094ca83          	lbu	s5,9(s1)
    800047b0:	0104ba03          	ld	s4,16(s1)
    800047b4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047b8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047bc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047c0:	0001d517          	auipc	a0,0x1d
    800047c4:	61850513          	addi	a0,a0,1560 # 80021dd8 <ftable>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	4d0080e7          	jalr	1232(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047d0:	4785                	li	a5,1
    800047d2:	04f90d63          	beq	s2,a5,8000482c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047d6:	3979                	addiw	s2,s2,-2
    800047d8:	4785                	li	a5,1
    800047da:	0527e063          	bltu	a5,s2,8000481a <fileclose+0xa8>
    begin_op();
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	ac8080e7          	jalr	-1336(ra) # 800042a6 <begin_op>
    iput(ff.ip);
    800047e6:	854e                	mv	a0,s3
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	2a6080e7          	jalr	678(ra) # 80003a8e <iput>
    end_op();
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	b36080e7          	jalr	-1226(ra) # 80004326 <end_op>
    800047f8:	a00d                	j	8000481a <fileclose+0xa8>
    panic("fileclose");
    800047fa:	00004517          	auipc	a0,0x4
    800047fe:	ea650513          	addi	a0,a0,-346 # 800086a0 <syscalls+0x258>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000480a:	0001d517          	auipc	a0,0x1d
    8000480e:	5ce50513          	addi	a0,a0,1486 # 80021dd8 <ftable>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
  }
}
    8000481a:	70e2                	ld	ra,56(sp)
    8000481c:	7442                	ld	s0,48(sp)
    8000481e:	74a2                	ld	s1,40(sp)
    80004820:	7902                	ld	s2,32(sp)
    80004822:	69e2                	ld	s3,24(sp)
    80004824:	6a42                	ld	s4,16(sp)
    80004826:	6aa2                	ld	s5,8(sp)
    80004828:	6121                	addi	sp,sp,64
    8000482a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000482c:	85d6                	mv	a1,s5
    8000482e:	8552                	mv	a0,s4
    80004830:	00000097          	auipc	ra,0x0
    80004834:	34c080e7          	jalr	844(ra) # 80004b7c <pipeclose>
    80004838:	b7cd                	j	8000481a <fileclose+0xa8>

000000008000483a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000483a:	715d                	addi	sp,sp,-80
    8000483c:	e486                	sd	ra,72(sp)
    8000483e:	e0a2                	sd	s0,64(sp)
    80004840:	fc26                	sd	s1,56(sp)
    80004842:	f84a                	sd	s2,48(sp)
    80004844:	f44e                	sd	s3,40(sp)
    80004846:	0880                	addi	s0,sp,80
    80004848:	84aa                	mv	s1,a0
    8000484a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000484c:	ffffd097          	auipc	ra,0xffffd
    80004850:	174080e7          	jalr	372(ra) # 800019c0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004854:	409c                	lw	a5,0(s1)
    80004856:	37f9                	addiw	a5,a5,-2
    80004858:	4705                	li	a4,1
    8000485a:	04f76763          	bltu	a4,a5,800048a8 <filestat+0x6e>
    8000485e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004860:	6c88                	ld	a0,24(s1)
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	072080e7          	jalr	114(ra) # 800038d4 <ilock>
    stati(f->ip, &st);
    8000486a:	fb840593          	addi	a1,s0,-72
    8000486e:	6c88                	ld	a0,24(s1)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	2ee080e7          	jalr	750(ra) # 80003b5e <stati>
    iunlock(f->ip);
    80004878:	6c88                	ld	a0,24(s1)
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	11c080e7          	jalr	284(ra) # 80003996 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004882:	46e1                	li	a3,24
    80004884:	fb840613          	addi	a2,s0,-72
    80004888:	85ce                	mv	a1,s3
    8000488a:	07893503          	ld	a0,120(s2)
    8000488e:	ffffd097          	auipc	ra,0xffffd
    80004892:	de4080e7          	jalr	-540(ra) # 80001672 <copyout>
    80004896:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000489a:	60a6                	ld	ra,72(sp)
    8000489c:	6406                	ld	s0,64(sp)
    8000489e:	74e2                	ld	s1,56(sp)
    800048a0:	7942                	ld	s2,48(sp)
    800048a2:	79a2                	ld	s3,40(sp)
    800048a4:	6161                	addi	sp,sp,80
    800048a6:	8082                	ret
  return -1;
    800048a8:	557d                	li	a0,-1
    800048aa:	bfc5                	j	8000489a <filestat+0x60>

00000000800048ac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048ac:	7179                	addi	sp,sp,-48
    800048ae:	f406                	sd	ra,40(sp)
    800048b0:	f022                	sd	s0,32(sp)
    800048b2:	ec26                	sd	s1,24(sp)
    800048b4:	e84a                	sd	s2,16(sp)
    800048b6:	e44e                	sd	s3,8(sp)
    800048b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048ba:	00854783          	lbu	a5,8(a0)
    800048be:	c3d5                	beqz	a5,80004962 <fileread+0xb6>
    800048c0:	84aa                	mv	s1,a0
    800048c2:	89ae                	mv	s3,a1
    800048c4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048c6:	411c                	lw	a5,0(a0)
    800048c8:	4705                	li	a4,1
    800048ca:	04e78963          	beq	a5,a4,8000491c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ce:	470d                	li	a4,3
    800048d0:	04e78d63          	beq	a5,a4,8000492a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048d4:	4709                	li	a4,2
    800048d6:	06e79e63          	bne	a5,a4,80004952 <fileread+0xa6>
    ilock(f->ip);
    800048da:	6d08                	ld	a0,24(a0)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	ff8080e7          	jalr	-8(ra) # 800038d4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048e4:	874a                	mv	a4,s2
    800048e6:	5094                	lw	a3,32(s1)
    800048e8:	864e                	mv	a2,s3
    800048ea:	4585                	li	a1,1
    800048ec:	6c88                	ld	a0,24(s1)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	29a080e7          	jalr	666(ra) # 80003b88 <readi>
    800048f6:	892a                	mv	s2,a0
    800048f8:	00a05563          	blez	a0,80004902 <fileread+0x56>
      f->off += r;
    800048fc:	509c                	lw	a5,32(s1)
    800048fe:	9fa9                	addw	a5,a5,a0
    80004900:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004902:	6c88                	ld	a0,24(s1)
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	092080e7          	jalr	146(ra) # 80003996 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000490c:	854a                	mv	a0,s2
    8000490e:	70a2                	ld	ra,40(sp)
    80004910:	7402                	ld	s0,32(sp)
    80004912:	64e2                	ld	s1,24(sp)
    80004914:	6942                	ld	s2,16(sp)
    80004916:	69a2                	ld	s3,8(sp)
    80004918:	6145                	addi	sp,sp,48
    8000491a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000491c:	6908                	ld	a0,16(a0)
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	3c8080e7          	jalr	968(ra) # 80004ce6 <piperead>
    80004926:	892a                	mv	s2,a0
    80004928:	b7d5                	j	8000490c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000492a:	02451783          	lh	a5,36(a0)
    8000492e:	03079693          	slli	a3,a5,0x30
    80004932:	92c1                	srli	a3,a3,0x30
    80004934:	4725                	li	a4,9
    80004936:	02d76863          	bltu	a4,a3,80004966 <fileread+0xba>
    8000493a:	0792                	slli	a5,a5,0x4
    8000493c:	0001d717          	auipc	a4,0x1d
    80004940:	3fc70713          	addi	a4,a4,1020 # 80021d38 <devsw>
    80004944:	97ba                	add	a5,a5,a4
    80004946:	639c                	ld	a5,0(a5)
    80004948:	c38d                	beqz	a5,8000496a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000494a:	4505                	li	a0,1
    8000494c:	9782                	jalr	a5
    8000494e:	892a                	mv	s2,a0
    80004950:	bf75                	j	8000490c <fileread+0x60>
    panic("fileread");
    80004952:	00004517          	auipc	a0,0x4
    80004956:	d5e50513          	addi	a0,a0,-674 # 800086b0 <syscalls+0x268>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>
    return -1;
    80004962:	597d                	li	s2,-1
    80004964:	b765                	j	8000490c <fileread+0x60>
      return -1;
    80004966:	597d                	li	s2,-1
    80004968:	b755                	j	8000490c <fileread+0x60>
    8000496a:	597d                	li	s2,-1
    8000496c:	b745                	j	8000490c <fileread+0x60>

000000008000496e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000496e:	715d                	addi	sp,sp,-80
    80004970:	e486                	sd	ra,72(sp)
    80004972:	e0a2                	sd	s0,64(sp)
    80004974:	fc26                	sd	s1,56(sp)
    80004976:	f84a                	sd	s2,48(sp)
    80004978:	f44e                	sd	s3,40(sp)
    8000497a:	f052                	sd	s4,32(sp)
    8000497c:	ec56                	sd	s5,24(sp)
    8000497e:	e85a                	sd	s6,16(sp)
    80004980:	e45e                	sd	s7,8(sp)
    80004982:	e062                	sd	s8,0(sp)
    80004984:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004986:	00954783          	lbu	a5,9(a0)
    8000498a:	10078663          	beqz	a5,80004a96 <filewrite+0x128>
    8000498e:	892a                	mv	s2,a0
    80004990:	8aae                	mv	s5,a1
    80004992:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004994:	411c                	lw	a5,0(a0)
    80004996:	4705                	li	a4,1
    80004998:	02e78263          	beq	a5,a4,800049bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000499c:	470d                	li	a4,3
    8000499e:	02e78663          	beq	a5,a4,800049ca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049a2:	4709                	li	a4,2
    800049a4:	0ee79163          	bne	a5,a4,80004a86 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049a8:	0ac05d63          	blez	a2,80004a62 <filewrite+0xf4>
    int i = 0;
    800049ac:	4981                	li	s3,0
    800049ae:	6b05                	lui	s6,0x1
    800049b0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049b4:	6b85                	lui	s7,0x1
    800049b6:	c00b8b9b          	addiw	s7,s7,-1024
    800049ba:	a861                	j	80004a52 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049bc:	6908                	ld	a0,16(a0)
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	22e080e7          	jalr	558(ra) # 80004bec <pipewrite>
    800049c6:	8a2a                	mv	s4,a0
    800049c8:	a045                	j	80004a68 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049ca:	02451783          	lh	a5,36(a0)
    800049ce:	03079693          	slli	a3,a5,0x30
    800049d2:	92c1                	srli	a3,a3,0x30
    800049d4:	4725                	li	a4,9
    800049d6:	0cd76263          	bltu	a4,a3,80004a9a <filewrite+0x12c>
    800049da:	0792                	slli	a5,a5,0x4
    800049dc:	0001d717          	auipc	a4,0x1d
    800049e0:	35c70713          	addi	a4,a4,860 # 80021d38 <devsw>
    800049e4:	97ba                	add	a5,a5,a4
    800049e6:	679c                	ld	a5,8(a5)
    800049e8:	cbdd                	beqz	a5,80004a9e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049ea:	4505                	li	a0,1
    800049ec:	9782                	jalr	a5
    800049ee:	8a2a                	mv	s4,a0
    800049f0:	a8a5                	j	80004a68 <filewrite+0xfa>
    800049f2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	8b0080e7          	jalr	-1872(ra) # 800042a6 <begin_op>
      ilock(f->ip);
    800049fe:	01893503          	ld	a0,24(s2)
    80004a02:	fffff097          	auipc	ra,0xfffff
    80004a06:	ed2080e7          	jalr	-302(ra) # 800038d4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a0a:	8762                	mv	a4,s8
    80004a0c:	02092683          	lw	a3,32(s2)
    80004a10:	01598633          	add	a2,s3,s5
    80004a14:	4585                	li	a1,1
    80004a16:	01893503          	ld	a0,24(s2)
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	266080e7          	jalr	614(ra) # 80003c80 <writei>
    80004a22:	84aa                	mv	s1,a0
    80004a24:	00a05763          	blez	a0,80004a32 <filewrite+0xc4>
        f->off += r;
    80004a28:	02092783          	lw	a5,32(s2)
    80004a2c:	9fa9                	addw	a5,a5,a0
    80004a2e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a32:	01893503          	ld	a0,24(s2)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	f60080e7          	jalr	-160(ra) # 80003996 <iunlock>
      end_op();
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	8e8080e7          	jalr	-1816(ra) # 80004326 <end_op>

      if(r != n1){
    80004a46:	009c1f63          	bne	s8,s1,80004a64 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a4a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a4e:	0149db63          	bge	s3,s4,80004a64 <filewrite+0xf6>
      int n1 = n - i;
    80004a52:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a56:	84be                	mv	s1,a5
    80004a58:	2781                	sext.w	a5,a5
    80004a5a:	f8fb5ce3          	bge	s6,a5,800049f2 <filewrite+0x84>
    80004a5e:	84de                	mv	s1,s7
    80004a60:	bf49                	j	800049f2 <filewrite+0x84>
    int i = 0;
    80004a62:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a64:	013a1f63          	bne	s4,s3,80004a82 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a68:	8552                	mv	a0,s4
    80004a6a:	60a6                	ld	ra,72(sp)
    80004a6c:	6406                	ld	s0,64(sp)
    80004a6e:	74e2                	ld	s1,56(sp)
    80004a70:	7942                	ld	s2,48(sp)
    80004a72:	79a2                	ld	s3,40(sp)
    80004a74:	7a02                	ld	s4,32(sp)
    80004a76:	6ae2                	ld	s5,24(sp)
    80004a78:	6b42                	ld	s6,16(sp)
    80004a7a:	6ba2                	ld	s7,8(sp)
    80004a7c:	6c02                	ld	s8,0(sp)
    80004a7e:	6161                	addi	sp,sp,80
    80004a80:	8082                	ret
    ret = (i == n ? n : -1);
    80004a82:	5a7d                	li	s4,-1
    80004a84:	b7d5                	j	80004a68 <filewrite+0xfa>
    panic("filewrite");
    80004a86:	00004517          	auipc	a0,0x4
    80004a8a:	c3a50513          	addi	a0,a0,-966 # 800086c0 <syscalls+0x278>
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
    return -1;
    80004a96:	5a7d                	li	s4,-1
    80004a98:	bfc1                	j	80004a68 <filewrite+0xfa>
      return -1;
    80004a9a:	5a7d                	li	s4,-1
    80004a9c:	b7f1                	j	80004a68 <filewrite+0xfa>
    80004a9e:	5a7d                	li	s4,-1
    80004aa0:	b7e1                	j	80004a68 <filewrite+0xfa>

0000000080004aa2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aa2:	7179                	addi	sp,sp,-48
    80004aa4:	f406                	sd	ra,40(sp)
    80004aa6:	f022                	sd	s0,32(sp)
    80004aa8:	ec26                	sd	s1,24(sp)
    80004aaa:	e84a                	sd	s2,16(sp)
    80004aac:	e44e                	sd	s3,8(sp)
    80004aae:	e052                	sd	s4,0(sp)
    80004ab0:	1800                	addi	s0,sp,48
    80004ab2:	84aa                	mv	s1,a0
    80004ab4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ab6:	0005b023          	sd	zero,0(a1)
    80004aba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004abe:	00000097          	auipc	ra,0x0
    80004ac2:	bf8080e7          	jalr	-1032(ra) # 800046b6 <filealloc>
    80004ac6:	e088                	sd	a0,0(s1)
    80004ac8:	c551                	beqz	a0,80004b54 <pipealloc+0xb2>
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	bec080e7          	jalr	-1044(ra) # 800046b6 <filealloc>
    80004ad2:	00aa3023          	sd	a0,0(s4)
    80004ad6:	c92d                	beqz	a0,80004b48 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	01c080e7          	jalr	28(ra) # 80000af4 <kalloc>
    80004ae0:	892a                	mv	s2,a0
    80004ae2:	c125                	beqz	a0,80004b42 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ae4:	4985                	li	s3,1
    80004ae6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004af2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004af6:	00004597          	auipc	a1,0x4
    80004afa:	bda58593          	addi	a1,a1,-1062 # 800086d0 <syscalls+0x288>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	056080e7          	jalr	86(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b06:	609c                	ld	a5,0(s1)
    80004b08:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b0c:	609c                	ld	a5,0(s1)
    80004b0e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b12:	609c                	ld	a5,0(s1)
    80004b14:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b18:	609c                	ld	a5,0(s1)
    80004b1a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b1e:	000a3783          	ld	a5,0(s4)
    80004b22:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b26:	000a3783          	ld	a5,0(s4)
    80004b2a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b2e:	000a3783          	ld	a5,0(s4)
    80004b32:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b36:	000a3783          	ld	a5,0(s4)
    80004b3a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b3e:	4501                	li	a0,0
    80004b40:	a025                	j	80004b68 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b42:	6088                	ld	a0,0(s1)
    80004b44:	e501                	bnez	a0,80004b4c <pipealloc+0xaa>
    80004b46:	a039                	j	80004b54 <pipealloc+0xb2>
    80004b48:	6088                	ld	a0,0(s1)
    80004b4a:	c51d                	beqz	a0,80004b78 <pipealloc+0xd6>
    fileclose(*f0);
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	c26080e7          	jalr	-986(ra) # 80004772 <fileclose>
  if(*f1)
    80004b54:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b58:	557d                	li	a0,-1
  if(*f1)
    80004b5a:	c799                	beqz	a5,80004b68 <pipealloc+0xc6>
    fileclose(*f1);
    80004b5c:	853e                	mv	a0,a5
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	c14080e7          	jalr	-1004(ra) # 80004772 <fileclose>
  return -1;
    80004b66:	557d                	li	a0,-1
}
    80004b68:	70a2                	ld	ra,40(sp)
    80004b6a:	7402                	ld	s0,32(sp)
    80004b6c:	64e2                	ld	s1,24(sp)
    80004b6e:	6942                	ld	s2,16(sp)
    80004b70:	69a2                	ld	s3,8(sp)
    80004b72:	6a02                	ld	s4,0(sp)
    80004b74:	6145                	addi	sp,sp,48
    80004b76:	8082                	ret
  return -1;
    80004b78:	557d                	li	a0,-1
    80004b7a:	b7fd                	j	80004b68 <pipealloc+0xc6>

0000000080004b7c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b7c:	1101                	addi	sp,sp,-32
    80004b7e:	ec06                	sd	ra,24(sp)
    80004b80:	e822                	sd	s0,16(sp)
    80004b82:	e426                	sd	s1,8(sp)
    80004b84:	e04a                	sd	s2,0(sp)
    80004b86:	1000                	addi	s0,sp,32
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	058080e7          	jalr	88(ra) # 80000be4 <acquire>
  if(writable){
    80004b94:	02090d63          	beqz	s2,80004bce <pipeclose+0x52>
    pi->writeopen = 0;
    80004b98:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b9c:	21848513          	addi	a0,s1,536
    80004ba0:	ffffe097          	auipc	ra,0xffffe
    80004ba4:	90c080e7          	jalr	-1780(ra) # 800024ac <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ba8:	2204b783          	ld	a5,544(s1)
    80004bac:	eb95                	bnez	a5,80004be0 <pipeclose+0x64>
    release(&pi->lock);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	0e8080e7          	jalr	232(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	e3e080e7          	jalr	-450(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bc2:	60e2                	ld	ra,24(sp)
    80004bc4:	6442                	ld	s0,16(sp)
    80004bc6:	64a2                	ld	s1,8(sp)
    80004bc8:	6902                	ld	s2,0(sp)
    80004bca:	6105                	addi	sp,sp,32
    80004bcc:	8082                	ret
    pi->readopen = 0;
    80004bce:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bd2:	21c48513          	addi	a0,s1,540
    80004bd6:	ffffe097          	auipc	ra,0xffffe
    80004bda:	8d6080e7          	jalr	-1834(ra) # 800024ac <wakeup>
    80004bde:	b7e9                	j	80004ba8 <pipeclose+0x2c>
    release(&pi->lock);
    80004be0:	8526                	mv	a0,s1
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	0b6080e7          	jalr	182(ra) # 80000c98 <release>
}
    80004bea:	bfe1                	j	80004bc2 <pipeclose+0x46>

0000000080004bec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bec:	7159                	addi	sp,sp,-112
    80004bee:	f486                	sd	ra,104(sp)
    80004bf0:	f0a2                	sd	s0,96(sp)
    80004bf2:	eca6                	sd	s1,88(sp)
    80004bf4:	e8ca                	sd	s2,80(sp)
    80004bf6:	e4ce                	sd	s3,72(sp)
    80004bf8:	e0d2                	sd	s4,64(sp)
    80004bfa:	fc56                	sd	s5,56(sp)
    80004bfc:	f85a                	sd	s6,48(sp)
    80004bfe:	f45e                	sd	s7,40(sp)
    80004c00:	f062                	sd	s8,32(sp)
    80004c02:	ec66                	sd	s9,24(sp)
    80004c04:	1880                	addi	s0,sp,112
    80004c06:	84aa                	mv	s1,a0
    80004c08:	8aae                	mv	s5,a1
    80004c0a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c0c:	ffffd097          	auipc	ra,0xffffd
    80004c10:	db4080e7          	jalr	-588(ra) # 800019c0 <myproc>
    80004c14:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	fcc080e7          	jalr	-52(ra) # 80000be4 <acquire>
  while(i < n){
    80004c20:	0d405163          	blez	s4,80004ce2 <pipewrite+0xf6>
    80004c24:	8ba6                	mv	s7,s1
  int i = 0;
    80004c26:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c28:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c2a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c2e:	21c48c13          	addi	s8,s1,540
    80004c32:	a08d                	j	80004c94 <pipewrite+0xa8>
      release(&pi->lock);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	062080e7          	jalr	98(ra) # 80000c98 <release>
      return -1;
    80004c3e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c40:	854a                	mv	a0,s2
    80004c42:	70a6                	ld	ra,104(sp)
    80004c44:	7406                	ld	s0,96(sp)
    80004c46:	64e6                	ld	s1,88(sp)
    80004c48:	6946                	ld	s2,80(sp)
    80004c4a:	69a6                	ld	s3,72(sp)
    80004c4c:	6a06                	ld	s4,64(sp)
    80004c4e:	7ae2                	ld	s5,56(sp)
    80004c50:	7b42                	ld	s6,48(sp)
    80004c52:	7ba2                	ld	s7,40(sp)
    80004c54:	7c02                	ld	s8,32(sp)
    80004c56:	6ce2                	ld	s9,24(sp)
    80004c58:	6165                	addi	sp,sp,112
    80004c5a:	8082                	ret
      wakeup(&pi->nread);
    80004c5c:	8566                	mv	a0,s9
    80004c5e:	ffffe097          	auipc	ra,0xffffe
    80004c62:	84e080e7          	jalr	-1970(ra) # 800024ac <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c66:	85de                	mv	a1,s7
    80004c68:	8562                	mv	a0,s8
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	6aa080e7          	jalr	1706(ra) # 80002314 <sleep>
    80004c72:	a839                	j	80004c90 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c74:	21c4a783          	lw	a5,540(s1)
    80004c78:	0017871b          	addiw	a4,a5,1
    80004c7c:	20e4ae23          	sw	a4,540(s1)
    80004c80:	1ff7f793          	andi	a5,a5,511
    80004c84:	97a6                	add	a5,a5,s1
    80004c86:	f9f44703          	lbu	a4,-97(s0)
    80004c8a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c8e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c90:	03495d63          	bge	s2,s4,80004cca <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c94:	2204a783          	lw	a5,544(s1)
    80004c98:	dfd1                	beqz	a5,80004c34 <pipewrite+0x48>
    80004c9a:	0289a783          	lw	a5,40(s3)
    80004c9e:	fbd9                	bnez	a5,80004c34 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ca0:	2184a783          	lw	a5,536(s1)
    80004ca4:	21c4a703          	lw	a4,540(s1)
    80004ca8:	2007879b          	addiw	a5,a5,512
    80004cac:	faf708e3          	beq	a4,a5,80004c5c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb0:	4685                	li	a3,1
    80004cb2:	01590633          	add	a2,s2,s5
    80004cb6:	f9f40593          	addi	a1,s0,-97
    80004cba:	0789b503          	ld	a0,120(s3)
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	a40080e7          	jalr	-1472(ra) # 800016fe <copyin>
    80004cc6:	fb6517e3          	bne	a0,s6,80004c74 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cca:	21848513          	addi	a0,s1,536
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	7de080e7          	jalr	2014(ra) # 800024ac <wakeup>
  release(&pi->lock);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	fc0080e7          	jalr	-64(ra) # 80000c98 <release>
  return i;
    80004ce0:	b785                	j	80004c40 <pipewrite+0x54>
  int i = 0;
    80004ce2:	4901                	li	s2,0
    80004ce4:	b7dd                	j	80004cca <pipewrite+0xde>

0000000080004ce6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ce6:	715d                	addi	sp,sp,-80
    80004ce8:	e486                	sd	ra,72(sp)
    80004cea:	e0a2                	sd	s0,64(sp)
    80004cec:	fc26                	sd	s1,56(sp)
    80004cee:	f84a                	sd	s2,48(sp)
    80004cf0:	f44e                	sd	s3,40(sp)
    80004cf2:	f052                	sd	s4,32(sp)
    80004cf4:	ec56                	sd	s5,24(sp)
    80004cf6:	e85a                	sd	s6,16(sp)
    80004cf8:	0880                	addi	s0,sp,80
    80004cfa:	84aa                	mv	s1,a0
    80004cfc:	892e                	mv	s2,a1
    80004cfe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	cc0080e7          	jalr	-832(ra) # 800019c0 <myproc>
    80004d08:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d0a:	8b26                	mv	s6,s1
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	ed6080e7          	jalr	-298(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d16:	2184a703          	lw	a4,536(s1)
    80004d1a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d1e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d22:	02f71463          	bne	a4,a5,80004d4a <piperead+0x64>
    80004d26:	2244a783          	lw	a5,548(s1)
    80004d2a:	c385                	beqz	a5,80004d4a <piperead+0x64>
    if(pr->killed){
    80004d2c:	028a2783          	lw	a5,40(s4)
    80004d30:	ebc1                	bnez	a5,80004dc0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d32:	85da                	mv	a1,s6
    80004d34:	854e                	mv	a0,s3
    80004d36:	ffffd097          	auipc	ra,0xffffd
    80004d3a:	5de080e7          	jalr	1502(ra) # 80002314 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d3e:	2184a703          	lw	a4,536(s1)
    80004d42:	21c4a783          	lw	a5,540(s1)
    80004d46:	fef700e3          	beq	a4,a5,80004d26 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d4a:	09505263          	blez	s5,80004dce <piperead+0xe8>
    80004d4e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d50:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d52:	2184a783          	lw	a5,536(s1)
    80004d56:	21c4a703          	lw	a4,540(s1)
    80004d5a:	02f70d63          	beq	a4,a5,80004d94 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d5e:	0017871b          	addiw	a4,a5,1
    80004d62:	20e4ac23          	sw	a4,536(s1)
    80004d66:	1ff7f793          	andi	a5,a5,511
    80004d6a:	97a6                	add	a5,a5,s1
    80004d6c:	0187c783          	lbu	a5,24(a5)
    80004d70:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d74:	4685                	li	a3,1
    80004d76:	fbf40613          	addi	a2,s0,-65
    80004d7a:	85ca                	mv	a1,s2
    80004d7c:	078a3503          	ld	a0,120(s4)
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	8f2080e7          	jalr	-1806(ra) # 80001672 <copyout>
    80004d88:	01650663          	beq	a0,s6,80004d94 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d8c:	2985                	addiw	s3,s3,1
    80004d8e:	0905                	addi	s2,s2,1
    80004d90:	fd3a91e3          	bne	s5,s3,80004d52 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d94:	21c48513          	addi	a0,s1,540
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	714080e7          	jalr	1812(ra) # 800024ac <wakeup>
  release(&pi->lock);
    80004da0:	8526                	mv	a0,s1
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	ef6080e7          	jalr	-266(ra) # 80000c98 <release>
  return i;
}
    80004daa:	854e                	mv	a0,s3
    80004dac:	60a6                	ld	ra,72(sp)
    80004dae:	6406                	ld	s0,64(sp)
    80004db0:	74e2                	ld	s1,56(sp)
    80004db2:	7942                	ld	s2,48(sp)
    80004db4:	79a2                	ld	s3,40(sp)
    80004db6:	7a02                	ld	s4,32(sp)
    80004db8:	6ae2                	ld	s5,24(sp)
    80004dba:	6b42                	ld	s6,16(sp)
    80004dbc:	6161                	addi	sp,sp,80
    80004dbe:	8082                	ret
      release(&pi->lock);
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	ed6080e7          	jalr	-298(ra) # 80000c98 <release>
      return -1;
    80004dca:	59fd                	li	s3,-1
    80004dcc:	bff9                	j	80004daa <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dce:	4981                	li	s3,0
    80004dd0:	b7d1                	j	80004d94 <piperead+0xae>

0000000080004dd2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dd2:	df010113          	addi	sp,sp,-528
    80004dd6:	20113423          	sd	ra,520(sp)
    80004dda:	20813023          	sd	s0,512(sp)
    80004dde:	ffa6                	sd	s1,504(sp)
    80004de0:	fbca                	sd	s2,496(sp)
    80004de2:	f7ce                	sd	s3,488(sp)
    80004de4:	f3d2                	sd	s4,480(sp)
    80004de6:	efd6                	sd	s5,472(sp)
    80004de8:	ebda                	sd	s6,464(sp)
    80004dea:	e7de                	sd	s7,456(sp)
    80004dec:	e3e2                	sd	s8,448(sp)
    80004dee:	ff66                	sd	s9,440(sp)
    80004df0:	fb6a                	sd	s10,432(sp)
    80004df2:	f76e                	sd	s11,424(sp)
    80004df4:	0c00                	addi	s0,sp,528
    80004df6:	84aa                	mv	s1,a0
    80004df8:	dea43c23          	sd	a0,-520(s0)
    80004dfc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	bc0080e7          	jalr	-1088(ra) # 800019c0 <myproc>
    80004e08:	892a                	mv	s2,a0

  begin_op();
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	49c080e7          	jalr	1180(ra) # 800042a6 <begin_op>

  if((ip = namei(path)) == 0){
    80004e12:	8526                	mv	a0,s1
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	276080e7          	jalr	630(ra) # 8000408a <namei>
    80004e1c:	c92d                	beqz	a0,80004e8e <exec+0xbc>
    80004e1e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	ab4080e7          	jalr	-1356(ra) # 800038d4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e28:	04000713          	li	a4,64
    80004e2c:	4681                	li	a3,0
    80004e2e:	e5040613          	addi	a2,s0,-432
    80004e32:	4581                	li	a1,0
    80004e34:	8526                	mv	a0,s1
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	d52080e7          	jalr	-686(ra) # 80003b88 <readi>
    80004e3e:	04000793          	li	a5,64
    80004e42:	00f51a63          	bne	a0,a5,80004e56 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e46:	e5042703          	lw	a4,-432(s0)
    80004e4a:	464c47b7          	lui	a5,0x464c4
    80004e4e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e52:	04f70463          	beq	a4,a5,80004e9a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e56:	8526                	mv	a0,s1
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	cde080e7          	jalr	-802(ra) # 80003b36 <iunlockput>
    end_op();
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	4c6080e7          	jalr	1222(ra) # 80004326 <end_op>
  }
  return -1;
    80004e68:	557d                	li	a0,-1
}
    80004e6a:	20813083          	ld	ra,520(sp)
    80004e6e:	20013403          	ld	s0,512(sp)
    80004e72:	74fe                	ld	s1,504(sp)
    80004e74:	795e                	ld	s2,496(sp)
    80004e76:	79be                	ld	s3,488(sp)
    80004e78:	7a1e                	ld	s4,480(sp)
    80004e7a:	6afe                	ld	s5,472(sp)
    80004e7c:	6b5e                	ld	s6,464(sp)
    80004e7e:	6bbe                	ld	s7,456(sp)
    80004e80:	6c1e                	ld	s8,448(sp)
    80004e82:	7cfa                	ld	s9,440(sp)
    80004e84:	7d5a                	ld	s10,432(sp)
    80004e86:	7dba                	ld	s11,424(sp)
    80004e88:	21010113          	addi	sp,sp,528
    80004e8c:	8082                	ret
    end_op();
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	498080e7          	jalr	1176(ra) # 80004326 <end_op>
    return -1;
    80004e96:	557d                	li	a0,-1
    80004e98:	bfc9                	j	80004e6a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e9a:	854a                	mv	a0,s2
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	be8080e7          	jalr	-1048(ra) # 80001a84 <proc_pagetable>
    80004ea4:	8baa                	mv	s7,a0
    80004ea6:	d945                	beqz	a0,80004e56 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea8:	e7042983          	lw	s3,-400(s0)
    80004eac:	e8845783          	lhu	a5,-376(s0)
    80004eb0:	c7ad                	beqz	a5,80004f1a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eb2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004eb6:	6c85                	lui	s9,0x1
    80004eb8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ebc:	def43823          	sd	a5,-528(s0)
    80004ec0:	a42d                	j	800050ea <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ec2:	00004517          	auipc	a0,0x4
    80004ec6:	81650513          	addi	a0,a0,-2026 # 800086d8 <syscalls+0x290>
    80004eca:	ffffb097          	auipc	ra,0xffffb
    80004ece:	674080e7          	jalr	1652(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ed2:	8756                	mv	a4,s5
    80004ed4:	012d86bb          	addw	a3,s11,s2
    80004ed8:	4581                	li	a1,0
    80004eda:	8526                	mv	a0,s1
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	cac080e7          	jalr	-852(ra) # 80003b88 <readi>
    80004ee4:	2501                	sext.w	a0,a0
    80004ee6:	1aaa9963          	bne	s5,a0,80005098 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004eea:	6785                	lui	a5,0x1
    80004eec:	0127893b          	addw	s2,a5,s2
    80004ef0:	77fd                	lui	a5,0xfffff
    80004ef2:	01478a3b          	addw	s4,a5,s4
    80004ef6:	1f897163          	bgeu	s2,s8,800050d8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004efa:	02091593          	slli	a1,s2,0x20
    80004efe:	9181                	srli	a1,a1,0x20
    80004f00:	95ea                	add	a1,a1,s10
    80004f02:	855e                	mv	a0,s7
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	16a080e7          	jalr	362(ra) # 8000106e <walkaddr>
    80004f0c:	862a                	mv	a2,a0
    if(pa == 0)
    80004f0e:	d955                	beqz	a0,80004ec2 <exec+0xf0>
      n = PGSIZE;
    80004f10:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f12:	fd9a70e3          	bgeu	s4,s9,80004ed2 <exec+0x100>
      n = sz - i;
    80004f16:	8ad2                	mv	s5,s4
    80004f18:	bf6d                	j	80004ed2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f1a:	4901                	li	s2,0
  iunlockput(ip);
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	c18080e7          	jalr	-1000(ra) # 80003b36 <iunlockput>
  end_op();
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	400080e7          	jalr	1024(ra) # 80004326 <end_op>
  p = myproc();
    80004f2e:	ffffd097          	auipc	ra,0xffffd
    80004f32:	a92080e7          	jalr	-1390(ra) # 800019c0 <myproc>
    80004f36:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f38:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80004f3c:	6785                	lui	a5,0x1
    80004f3e:	17fd                	addi	a5,a5,-1
    80004f40:	993e                	add	s2,s2,a5
    80004f42:	757d                	lui	a0,0xfffff
    80004f44:	00a977b3          	and	a5,s2,a0
    80004f48:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f4c:	6609                	lui	a2,0x2
    80004f4e:	963e                	add	a2,a2,a5
    80004f50:	85be                	mv	a1,a5
    80004f52:	855e                	mv	a0,s7
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	4ce080e7          	jalr	1230(ra) # 80001422 <uvmalloc>
    80004f5c:	8b2a                	mv	s6,a0
  ip = 0;
    80004f5e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f60:	12050c63          	beqz	a0,80005098 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f64:	75f9                	lui	a1,0xffffe
    80004f66:	95aa                	add	a1,a1,a0
    80004f68:	855e                	mv	a0,s7
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	6d6080e7          	jalr	1750(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f72:	7c7d                	lui	s8,0xfffff
    80004f74:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f76:	e0043783          	ld	a5,-512(s0)
    80004f7a:	6388                	ld	a0,0(a5)
    80004f7c:	c535                	beqz	a0,80004fe8 <exec+0x216>
    80004f7e:	e9040993          	addi	s3,s0,-368
    80004f82:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f86:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	edc080e7          	jalr	-292(ra) # 80000e64 <strlen>
    80004f90:	2505                	addiw	a0,a0,1
    80004f92:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f96:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f9a:	13896363          	bltu	s2,s8,800050c0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f9e:	e0043d83          	ld	s11,-512(s0)
    80004fa2:	000dba03          	ld	s4,0(s11)
    80004fa6:	8552                	mv	a0,s4
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	ebc080e7          	jalr	-324(ra) # 80000e64 <strlen>
    80004fb0:	0015069b          	addiw	a3,a0,1
    80004fb4:	8652                	mv	a2,s4
    80004fb6:	85ca                	mv	a1,s2
    80004fb8:	855e                	mv	a0,s7
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	6b8080e7          	jalr	1720(ra) # 80001672 <copyout>
    80004fc2:	10054363          	bltz	a0,800050c8 <exec+0x2f6>
    ustack[argc] = sp;
    80004fc6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fca:	0485                	addi	s1,s1,1
    80004fcc:	008d8793          	addi	a5,s11,8
    80004fd0:	e0f43023          	sd	a5,-512(s0)
    80004fd4:	008db503          	ld	a0,8(s11)
    80004fd8:	c911                	beqz	a0,80004fec <exec+0x21a>
    if(argc >= MAXARG)
    80004fda:	09a1                	addi	s3,s3,8
    80004fdc:	fb3c96e3          	bne	s9,s3,80004f88 <exec+0x1b6>
  sz = sz1;
    80004fe0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe4:	4481                	li	s1,0
    80004fe6:	a84d                	j	80005098 <exec+0x2c6>
  sp = sz;
    80004fe8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fea:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fec:	00349793          	slli	a5,s1,0x3
    80004ff0:	f9040713          	addi	a4,s0,-112
    80004ff4:	97ba                	add	a5,a5,a4
    80004ff6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ffa:	00148693          	addi	a3,s1,1
    80004ffe:	068e                	slli	a3,a3,0x3
    80005000:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005004:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005008:	01897663          	bgeu	s2,s8,80005014 <exec+0x242>
  sz = sz1;
    8000500c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005010:	4481                	li	s1,0
    80005012:	a059                	j	80005098 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005014:	e9040613          	addi	a2,s0,-368
    80005018:	85ca                	mv	a1,s2
    8000501a:	855e                	mv	a0,s7
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	656080e7          	jalr	1622(ra) # 80001672 <copyout>
    80005024:	0a054663          	bltz	a0,800050d0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005028:	080ab783          	ld	a5,128(s5)
    8000502c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005030:	df843783          	ld	a5,-520(s0)
    80005034:	0007c703          	lbu	a4,0(a5)
    80005038:	cf11                	beqz	a4,80005054 <exec+0x282>
    8000503a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000503c:	02f00693          	li	a3,47
    80005040:	a039                	j	8000504e <exec+0x27c>
      last = s+1;
    80005042:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005046:	0785                	addi	a5,a5,1
    80005048:	fff7c703          	lbu	a4,-1(a5)
    8000504c:	c701                	beqz	a4,80005054 <exec+0x282>
    if(*s == '/')
    8000504e:	fed71ce3          	bne	a4,a3,80005046 <exec+0x274>
    80005052:	bfc5                	j	80005042 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005054:	4641                	li	a2,16
    80005056:	df843583          	ld	a1,-520(s0)
    8000505a:	180a8513          	addi	a0,s5,384
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	dd4080e7          	jalr	-556(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005066:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    8000506a:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    8000506e:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005072:	080ab783          	ld	a5,128(s5)
    80005076:	e6843703          	ld	a4,-408(s0)
    8000507a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000507c:	080ab783          	ld	a5,128(s5)
    80005080:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005084:	85ea                	mv	a1,s10
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	a9a080e7          	jalr	-1382(ra) # 80001b20 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000508e:	0004851b          	sext.w	a0,s1
    80005092:	bbe1                	j	80004e6a <exec+0x98>
    80005094:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005098:	e0843583          	ld	a1,-504(s0)
    8000509c:	855e                	mv	a0,s7
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	a82080e7          	jalr	-1406(ra) # 80001b20 <proc_freepagetable>
  if(ip){
    800050a6:	da0498e3          	bnez	s1,80004e56 <exec+0x84>
  return -1;
    800050aa:	557d                	li	a0,-1
    800050ac:	bb7d                	j	80004e6a <exec+0x98>
    800050ae:	e1243423          	sd	s2,-504(s0)
    800050b2:	b7dd                	j	80005098 <exec+0x2c6>
    800050b4:	e1243423          	sd	s2,-504(s0)
    800050b8:	b7c5                	j	80005098 <exec+0x2c6>
    800050ba:	e1243423          	sd	s2,-504(s0)
    800050be:	bfe9                	j	80005098 <exec+0x2c6>
  sz = sz1;
    800050c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c4:	4481                	li	s1,0
    800050c6:	bfc9                	j	80005098 <exec+0x2c6>
  sz = sz1;
    800050c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050cc:	4481                	li	s1,0
    800050ce:	b7e9                	j	80005098 <exec+0x2c6>
  sz = sz1;
    800050d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d4:	4481                	li	s1,0
    800050d6:	b7c9                	j	80005098 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050d8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050dc:	2b05                	addiw	s6,s6,1
    800050de:	0389899b          	addiw	s3,s3,56
    800050e2:	e8845783          	lhu	a5,-376(s0)
    800050e6:	e2fb5be3          	bge	s6,a5,80004f1c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ea:	2981                	sext.w	s3,s3
    800050ec:	03800713          	li	a4,56
    800050f0:	86ce                	mv	a3,s3
    800050f2:	e1840613          	addi	a2,s0,-488
    800050f6:	4581                	li	a1,0
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	a8e080e7          	jalr	-1394(ra) # 80003b88 <readi>
    80005102:	03800793          	li	a5,56
    80005106:	f8f517e3          	bne	a0,a5,80005094 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000510a:	e1842783          	lw	a5,-488(s0)
    8000510e:	4705                	li	a4,1
    80005110:	fce796e3          	bne	a5,a4,800050dc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005114:	e4043603          	ld	a2,-448(s0)
    80005118:	e3843783          	ld	a5,-456(s0)
    8000511c:	f8f669e3          	bltu	a2,a5,800050ae <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005120:	e2843783          	ld	a5,-472(s0)
    80005124:	963e                	add	a2,a2,a5
    80005126:	f8f667e3          	bltu	a2,a5,800050b4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000512a:	85ca                	mv	a1,s2
    8000512c:	855e                	mv	a0,s7
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	2f4080e7          	jalr	756(ra) # 80001422 <uvmalloc>
    80005136:	e0a43423          	sd	a0,-504(s0)
    8000513a:	d141                	beqz	a0,800050ba <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000513c:	e2843d03          	ld	s10,-472(s0)
    80005140:	df043783          	ld	a5,-528(s0)
    80005144:	00fd77b3          	and	a5,s10,a5
    80005148:	fba1                	bnez	a5,80005098 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000514a:	e2042d83          	lw	s11,-480(s0)
    8000514e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005152:	f80c03e3          	beqz	s8,800050d8 <exec+0x306>
    80005156:	8a62                	mv	s4,s8
    80005158:	4901                	li	s2,0
    8000515a:	b345                	j	80004efa <exec+0x128>

000000008000515c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000515c:	7179                	addi	sp,sp,-48
    8000515e:	f406                	sd	ra,40(sp)
    80005160:	f022                	sd	s0,32(sp)
    80005162:	ec26                	sd	s1,24(sp)
    80005164:	e84a                	sd	s2,16(sp)
    80005166:	1800                	addi	s0,sp,48
    80005168:	892e                	mv	s2,a1
    8000516a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000516c:	fdc40593          	addi	a1,s0,-36
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	ba8080e7          	jalr	-1112(ra) # 80002d18 <argint>
    80005178:	04054063          	bltz	a0,800051b8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000517c:	fdc42703          	lw	a4,-36(s0)
    80005180:	47bd                	li	a5,15
    80005182:	02e7ed63          	bltu	a5,a4,800051bc <argfd+0x60>
    80005186:	ffffd097          	auipc	ra,0xffffd
    8000518a:	83a080e7          	jalr	-1990(ra) # 800019c0 <myproc>
    8000518e:	fdc42703          	lw	a4,-36(s0)
    80005192:	01e70793          	addi	a5,a4,30
    80005196:	078e                	slli	a5,a5,0x3
    80005198:	953e                	add	a0,a0,a5
    8000519a:	651c                	ld	a5,8(a0)
    8000519c:	c395                	beqz	a5,800051c0 <argfd+0x64>
    return -1;
  if(pfd)
    8000519e:	00090463          	beqz	s2,800051a6 <argfd+0x4a>
    *pfd = fd;
    800051a2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a6:	4501                	li	a0,0
  if(pf)
    800051a8:	c091                	beqz	s1,800051ac <argfd+0x50>
    *pf = f;
    800051aa:	e09c                	sd	a5,0(s1)
}
    800051ac:	70a2                	ld	ra,40(sp)
    800051ae:	7402                	ld	s0,32(sp)
    800051b0:	64e2                	ld	s1,24(sp)
    800051b2:	6942                	ld	s2,16(sp)
    800051b4:	6145                	addi	sp,sp,48
    800051b6:	8082                	ret
    return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	bfcd                	j	800051ac <argfd+0x50>
    return -1;
    800051bc:	557d                	li	a0,-1
    800051be:	b7fd                	j	800051ac <argfd+0x50>
    800051c0:	557d                	li	a0,-1
    800051c2:	b7ed                	j	800051ac <argfd+0x50>

00000000800051c4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c4:	1101                	addi	sp,sp,-32
    800051c6:	ec06                	sd	ra,24(sp)
    800051c8:	e822                	sd	s0,16(sp)
    800051ca:	e426                	sd	s1,8(sp)
    800051cc:	1000                	addi	s0,sp,32
    800051ce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	7f0080e7          	jalr	2032(ra) # 800019c0 <myproc>
    800051d8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051da:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    800051de:	4501                	li	a0,0
    800051e0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051e2:	6398                	ld	a4,0(a5)
    800051e4:	cb19                	beqz	a4,800051fa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e6:	2505                	addiw	a0,a0,1
    800051e8:	07a1                	addi	a5,a5,8
    800051ea:	fed51ce3          	bne	a0,a3,800051e2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ee:	557d                	li	a0,-1
}
    800051f0:	60e2                	ld	ra,24(sp)
    800051f2:	6442                	ld	s0,16(sp)
    800051f4:	64a2                	ld	s1,8(sp)
    800051f6:	6105                	addi	sp,sp,32
    800051f8:	8082                	ret
      p->ofile[fd] = f;
    800051fa:	01e50793          	addi	a5,a0,30
    800051fe:	078e                	slli	a5,a5,0x3
    80005200:	963e                	add	a2,a2,a5
    80005202:	e604                	sd	s1,8(a2)
      return fd;
    80005204:	b7f5                	j	800051f0 <fdalloc+0x2c>

0000000080005206 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005206:	715d                	addi	sp,sp,-80
    80005208:	e486                	sd	ra,72(sp)
    8000520a:	e0a2                	sd	s0,64(sp)
    8000520c:	fc26                	sd	s1,56(sp)
    8000520e:	f84a                	sd	s2,48(sp)
    80005210:	f44e                	sd	s3,40(sp)
    80005212:	f052                	sd	s4,32(sp)
    80005214:	ec56                	sd	s5,24(sp)
    80005216:	0880                	addi	s0,sp,80
    80005218:	89ae                	mv	s3,a1
    8000521a:	8ab2                	mv	s5,a2
    8000521c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521e:	fb040593          	addi	a1,s0,-80
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	e86080e7          	jalr	-378(ra) # 800040a8 <nameiparent>
    8000522a:	892a                	mv	s2,a0
    8000522c:	12050f63          	beqz	a0,8000536a <create+0x164>
    return 0;

  ilock(dp);
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	6a4080e7          	jalr	1700(ra) # 800038d4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005238:	4601                	li	a2,0
    8000523a:	fb040593          	addi	a1,s0,-80
    8000523e:	854a                	mv	a0,s2
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	b78080e7          	jalr	-1160(ra) # 80003db8 <dirlookup>
    80005248:	84aa                	mv	s1,a0
    8000524a:	c921                	beqz	a0,8000529a <create+0x94>
    iunlockput(dp);
    8000524c:	854a                	mv	a0,s2
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	8e8080e7          	jalr	-1816(ra) # 80003b36 <iunlockput>
    ilock(ip);
    80005256:	8526                	mv	a0,s1
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	67c080e7          	jalr	1660(ra) # 800038d4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005260:	2981                	sext.w	s3,s3
    80005262:	4789                	li	a5,2
    80005264:	02f99463          	bne	s3,a5,8000528c <create+0x86>
    80005268:	0444d783          	lhu	a5,68(s1)
    8000526c:	37f9                	addiw	a5,a5,-2
    8000526e:	17c2                	slli	a5,a5,0x30
    80005270:	93c1                	srli	a5,a5,0x30
    80005272:	4705                	li	a4,1
    80005274:	00f76c63          	bltu	a4,a5,8000528c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005278:	8526                	mv	a0,s1
    8000527a:	60a6                	ld	ra,72(sp)
    8000527c:	6406                	ld	s0,64(sp)
    8000527e:	74e2                	ld	s1,56(sp)
    80005280:	7942                	ld	s2,48(sp)
    80005282:	79a2                	ld	s3,40(sp)
    80005284:	7a02                	ld	s4,32(sp)
    80005286:	6ae2                	ld	s5,24(sp)
    80005288:	6161                	addi	sp,sp,80
    8000528a:	8082                	ret
    iunlockput(ip);
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	8a8080e7          	jalr	-1880(ra) # 80003b36 <iunlockput>
    return 0;
    80005296:	4481                	li	s1,0
    80005298:	b7c5                	j	80005278 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000529a:	85ce                	mv	a1,s3
    8000529c:	00092503          	lw	a0,0(s2)
    800052a0:	ffffe097          	auipc	ra,0xffffe
    800052a4:	49c080e7          	jalr	1180(ra) # 8000373c <ialloc>
    800052a8:	84aa                	mv	s1,a0
    800052aa:	c529                	beqz	a0,800052f4 <create+0xee>
  ilock(ip);
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	628080e7          	jalr	1576(ra) # 800038d4 <ilock>
  ip->major = major;
    800052b4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052bc:	4785                	li	a5,1
    800052be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052c2:	8526                	mv	a0,s1
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	546080e7          	jalr	1350(ra) # 8000380a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052cc:	2981                	sext.w	s3,s3
    800052ce:	4785                	li	a5,1
    800052d0:	02f98a63          	beq	s3,a5,80005304 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d4:	40d0                	lw	a2,4(s1)
    800052d6:	fb040593          	addi	a1,s0,-80
    800052da:	854a                	mv	a0,s2
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	cec080e7          	jalr	-788(ra) # 80003fc8 <dirlink>
    800052e4:	06054b63          	bltz	a0,8000535a <create+0x154>
  iunlockput(dp);
    800052e8:	854a                	mv	a0,s2
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	84c080e7          	jalr	-1972(ra) # 80003b36 <iunlockput>
  return ip;
    800052f2:	b759                	j	80005278 <create+0x72>
    panic("create: ialloc");
    800052f4:	00003517          	auipc	a0,0x3
    800052f8:	40450513          	addi	a0,a0,1028 # 800086f8 <syscalls+0x2b0>
    800052fc:	ffffb097          	auipc	ra,0xffffb
    80005300:	242080e7          	jalr	578(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005304:	04a95783          	lhu	a5,74(s2)
    80005308:	2785                	addiw	a5,a5,1
    8000530a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000530e:	854a                	mv	a0,s2
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	4fa080e7          	jalr	1274(ra) # 8000380a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005318:	40d0                	lw	a2,4(s1)
    8000531a:	00003597          	auipc	a1,0x3
    8000531e:	3ee58593          	addi	a1,a1,1006 # 80008708 <syscalls+0x2c0>
    80005322:	8526                	mv	a0,s1
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	ca4080e7          	jalr	-860(ra) # 80003fc8 <dirlink>
    8000532c:	00054f63          	bltz	a0,8000534a <create+0x144>
    80005330:	00492603          	lw	a2,4(s2)
    80005334:	00003597          	auipc	a1,0x3
    80005338:	3dc58593          	addi	a1,a1,988 # 80008710 <syscalls+0x2c8>
    8000533c:	8526                	mv	a0,s1
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	c8a080e7          	jalr	-886(ra) # 80003fc8 <dirlink>
    80005346:	f80557e3          	bgez	a0,800052d4 <create+0xce>
      panic("create dots");
    8000534a:	00003517          	auipc	a0,0x3
    8000534e:	3ce50513          	addi	a0,a0,974 # 80008718 <syscalls+0x2d0>
    80005352:	ffffb097          	auipc	ra,0xffffb
    80005356:	1ec080e7          	jalr	492(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000535a:	00003517          	auipc	a0,0x3
    8000535e:	3ce50513          	addi	a0,a0,974 # 80008728 <syscalls+0x2e0>
    80005362:	ffffb097          	auipc	ra,0xffffb
    80005366:	1dc080e7          	jalr	476(ra) # 8000053e <panic>
    return 0;
    8000536a:	84aa                	mv	s1,a0
    8000536c:	b731                	j	80005278 <create+0x72>

000000008000536e <sys_dup>:
{
    8000536e:	7179                	addi	sp,sp,-48
    80005370:	f406                	sd	ra,40(sp)
    80005372:	f022                	sd	s0,32(sp)
    80005374:	ec26                	sd	s1,24(sp)
    80005376:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005378:	fd840613          	addi	a2,s0,-40
    8000537c:	4581                	li	a1,0
    8000537e:	4501                	li	a0,0
    80005380:	00000097          	auipc	ra,0x0
    80005384:	ddc080e7          	jalr	-548(ra) # 8000515c <argfd>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000538a:	02054363          	bltz	a0,800053b0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538e:	fd843503          	ld	a0,-40(s0)
    80005392:	00000097          	auipc	ra,0x0
    80005396:	e32080e7          	jalr	-462(ra) # 800051c4 <fdalloc>
    8000539a:	84aa                	mv	s1,a0
    return -1;
    8000539c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539e:	00054963          	bltz	a0,800053b0 <sys_dup+0x42>
  filedup(f);
    800053a2:	fd843503          	ld	a0,-40(s0)
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	37a080e7          	jalr	890(ra) # 80004720 <filedup>
  return fd;
    800053ae:	87a6                	mv	a5,s1
}
    800053b0:	853e                	mv	a0,a5
    800053b2:	70a2                	ld	ra,40(sp)
    800053b4:	7402                	ld	s0,32(sp)
    800053b6:	64e2                	ld	s1,24(sp)
    800053b8:	6145                	addi	sp,sp,48
    800053ba:	8082                	ret

00000000800053bc <sys_read>:
{
    800053bc:	7179                	addi	sp,sp,-48
    800053be:	f406                	sd	ra,40(sp)
    800053c0:	f022                	sd	s0,32(sp)
    800053c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c4:	fe840613          	addi	a2,s0,-24
    800053c8:	4581                	li	a1,0
    800053ca:	4501                	li	a0,0
    800053cc:	00000097          	auipc	ra,0x0
    800053d0:	d90080e7          	jalr	-624(ra) # 8000515c <argfd>
    return -1;
    800053d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d6:	04054163          	bltz	a0,80005418 <sys_read+0x5c>
    800053da:	fe440593          	addi	a1,s0,-28
    800053de:	4509                	li	a0,2
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	938080e7          	jalr	-1736(ra) # 80002d18 <argint>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ea:	02054763          	bltz	a0,80005418 <sys_read+0x5c>
    800053ee:	fd840593          	addi	a1,s0,-40
    800053f2:	4505                	li	a0,1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	946080e7          	jalr	-1722(ra) # 80002d3a <argaddr>
    return -1;
    800053fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fe:	00054d63          	bltz	a0,80005418 <sys_read+0x5c>
  return fileread(f, p, n);
    80005402:	fe442603          	lw	a2,-28(s0)
    80005406:	fd843583          	ld	a1,-40(s0)
    8000540a:	fe843503          	ld	a0,-24(s0)
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	49e080e7          	jalr	1182(ra) # 800048ac <fileread>
    80005416:	87aa                	mv	a5,a0
}
    80005418:	853e                	mv	a0,a5
    8000541a:	70a2                	ld	ra,40(sp)
    8000541c:	7402                	ld	s0,32(sp)
    8000541e:	6145                	addi	sp,sp,48
    80005420:	8082                	ret

0000000080005422 <sys_write>:
{
    80005422:	7179                	addi	sp,sp,-48
    80005424:	f406                	sd	ra,40(sp)
    80005426:	f022                	sd	s0,32(sp)
    80005428:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000542a:	fe840613          	addi	a2,s0,-24
    8000542e:	4581                	li	a1,0
    80005430:	4501                	li	a0,0
    80005432:	00000097          	auipc	ra,0x0
    80005436:	d2a080e7          	jalr	-726(ra) # 8000515c <argfd>
    return -1;
    8000543a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543c:	04054163          	bltz	a0,8000547e <sys_write+0x5c>
    80005440:	fe440593          	addi	a1,s0,-28
    80005444:	4509                	li	a0,2
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	8d2080e7          	jalr	-1838(ra) # 80002d18 <argint>
    return -1;
    8000544e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005450:	02054763          	bltz	a0,8000547e <sys_write+0x5c>
    80005454:	fd840593          	addi	a1,s0,-40
    80005458:	4505                	li	a0,1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	8e0080e7          	jalr	-1824(ra) # 80002d3a <argaddr>
    return -1;
    80005462:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005464:	00054d63          	bltz	a0,8000547e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005468:	fe442603          	lw	a2,-28(s0)
    8000546c:	fd843583          	ld	a1,-40(s0)
    80005470:	fe843503          	ld	a0,-24(s0)
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	4fa080e7          	jalr	1274(ra) # 8000496e <filewrite>
    8000547c:	87aa                	mv	a5,a0
}
    8000547e:	853e                	mv	a0,a5
    80005480:	70a2                	ld	ra,40(sp)
    80005482:	7402                	ld	s0,32(sp)
    80005484:	6145                	addi	sp,sp,48
    80005486:	8082                	ret

0000000080005488 <sys_close>:
{
    80005488:	1101                	addi	sp,sp,-32
    8000548a:	ec06                	sd	ra,24(sp)
    8000548c:	e822                	sd	s0,16(sp)
    8000548e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005490:	fe040613          	addi	a2,s0,-32
    80005494:	fec40593          	addi	a1,s0,-20
    80005498:	4501                	li	a0,0
    8000549a:	00000097          	auipc	ra,0x0
    8000549e:	cc2080e7          	jalr	-830(ra) # 8000515c <argfd>
    return -1;
    800054a2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054a4:	02054463          	bltz	a0,800054cc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a8:	ffffc097          	auipc	ra,0xffffc
    800054ac:	518080e7          	jalr	1304(ra) # 800019c0 <myproc>
    800054b0:	fec42783          	lw	a5,-20(s0)
    800054b4:	07f9                	addi	a5,a5,30
    800054b6:	078e                	slli	a5,a5,0x3
    800054b8:	97aa                	add	a5,a5,a0
    800054ba:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800054be:	fe043503          	ld	a0,-32(s0)
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	2b0080e7          	jalr	688(ra) # 80004772 <fileclose>
  return 0;
    800054ca:	4781                	li	a5,0
}
    800054cc:	853e                	mv	a0,a5
    800054ce:	60e2                	ld	ra,24(sp)
    800054d0:	6442                	ld	s0,16(sp)
    800054d2:	6105                	addi	sp,sp,32
    800054d4:	8082                	ret

00000000800054d6 <sys_fstat>:
{
    800054d6:	1101                	addi	sp,sp,-32
    800054d8:	ec06                	sd	ra,24(sp)
    800054da:	e822                	sd	s0,16(sp)
    800054dc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054de:	fe840613          	addi	a2,s0,-24
    800054e2:	4581                	li	a1,0
    800054e4:	4501                	li	a0,0
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	c76080e7          	jalr	-906(ra) # 8000515c <argfd>
    return -1;
    800054ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054f0:	02054563          	bltz	a0,8000551a <sys_fstat+0x44>
    800054f4:	fe040593          	addi	a1,s0,-32
    800054f8:	4505                	li	a0,1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	840080e7          	jalr	-1984(ra) # 80002d3a <argaddr>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005504:	00054b63          	bltz	a0,8000551a <sys_fstat+0x44>
  return filestat(f, st);
    80005508:	fe043583          	ld	a1,-32(s0)
    8000550c:	fe843503          	ld	a0,-24(s0)
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	32a080e7          	jalr	810(ra) # 8000483a <filestat>
    80005518:	87aa                	mv	a5,a0
}
    8000551a:	853e                	mv	a0,a5
    8000551c:	60e2                	ld	ra,24(sp)
    8000551e:	6442                	ld	s0,16(sp)
    80005520:	6105                	addi	sp,sp,32
    80005522:	8082                	ret

0000000080005524 <sys_link>:
{
    80005524:	7169                	addi	sp,sp,-304
    80005526:	f606                	sd	ra,296(sp)
    80005528:	f222                	sd	s0,288(sp)
    8000552a:	ee26                	sd	s1,280(sp)
    8000552c:	ea4a                	sd	s2,272(sp)
    8000552e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005530:	08000613          	li	a2,128
    80005534:	ed040593          	addi	a1,s0,-304
    80005538:	4501                	li	a0,0
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	822080e7          	jalr	-2014(ra) # 80002d5c <argstr>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005544:	10054e63          	bltz	a0,80005660 <sys_link+0x13c>
    80005548:	08000613          	li	a2,128
    8000554c:	f5040593          	addi	a1,s0,-176
    80005550:	4505                	li	a0,1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	80a080e7          	jalr	-2038(ra) # 80002d5c <argstr>
    return -1;
    8000555a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000555c:	10054263          	bltz	a0,80005660 <sys_link+0x13c>
  begin_op();
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	d46080e7          	jalr	-698(ra) # 800042a6 <begin_op>
  if((ip = namei(old)) == 0){
    80005568:	ed040513          	addi	a0,s0,-304
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	b1e080e7          	jalr	-1250(ra) # 8000408a <namei>
    80005574:	84aa                	mv	s1,a0
    80005576:	c551                	beqz	a0,80005602 <sys_link+0xde>
  ilock(ip);
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	35c080e7          	jalr	860(ra) # 800038d4 <ilock>
  if(ip->type == T_DIR){
    80005580:	04449703          	lh	a4,68(s1)
    80005584:	4785                	li	a5,1
    80005586:	08f70463          	beq	a4,a5,8000560e <sys_link+0xea>
  ip->nlink++;
    8000558a:	04a4d783          	lhu	a5,74(s1)
    8000558e:	2785                	addiw	a5,a5,1
    80005590:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	274080e7          	jalr	628(ra) # 8000380a <iupdate>
  iunlock(ip);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	3f6080e7          	jalr	1014(ra) # 80003996 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a8:	fd040593          	addi	a1,s0,-48
    800055ac:	f5040513          	addi	a0,s0,-176
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	af8080e7          	jalr	-1288(ra) # 800040a8 <nameiparent>
    800055b8:	892a                	mv	s2,a0
    800055ba:	c935                	beqz	a0,8000562e <sys_link+0x10a>
  ilock(dp);
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	318080e7          	jalr	792(ra) # 800038d4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c4:	00092703          	lw	a4,0(s2)
    800055c8:	409c                	lw	a5,0(s1)
    800055ca:	04f71d63          	bne	a4,a5,80005624 <sys_link+0x100>
    800055ce:	40d0                	lw	a2,4(s1)
    800055d0:	fd040593          	addi	a1,s0,-48
    800055d4:	854a                	mv	a0,s2
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	9f2080e7          	jalr	-1550(ra) # 80003fc8 <dirlink>
    800055de:	04054363          	bltz	a0,80005624 <sys_link+0x100>
  iunlockput(dp);
    800055e2:	854a                	mv	a0,s2
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	552080e7          	jalr	1362(ra) # 80003b36 <iunlockput>
  iput(ip);
    800055ec:	8526                	mv	a0,s1
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	4a0080e7          	jalr	1184(ra) # 80003a8e <iput>
  end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	d30080e7          	jalr	-720(ra) # 80004326 <end_op>
  return 0;
    800055fe:	4781                	li	a5,0
    80005600:	a085                	j	80005660 <sys_link+0x13c>
    end_op();
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	d24080e7          	jalr	-732(ra) # 80004326 <end_op>
    return -1;
    8000560a:	57fd                	li	a5,-1
    8000560c:	a891                	j	80005660 <sys_link+0x13c>
    iunlockput(ip);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	526080e7          	jalr	1318(ra) # 80003b36 <iunlockput>
    end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	d0e080e7          	jalr	-754(ra) # 80004326 <end_op>
    return -1;
    80005620:	57fd                	li	a5,-1
    80005622:	a83d                	j	80005660 <sys_link+0x13c>
    iunlockput(dp);
    80005624:	854a                	mv	a0,s2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	510080e7          	jalr	1296(ra) # 80003b36 <iunlockput>
  ilock(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	2a4080e7          	jalr	676(ra) # 800038d4 <ilock>
  ip->nlink--;
    80005638:	04a4d783          	lhu	a5,74(s1)
    8000563c:	37fd                	addiw	a5,a5,-1
    8000563e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	1c6080e7          	jalr	454(ra) # 8000380a <iupdate>
  iunlockput(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	4e8080e7          	jalr	1256(ra) # 80003b36 <iunlockput>
  end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	cd0080e7          	jalr	-816(ra) # 80004326 <end_op>
  return -1;
    8000565e:	57fd                	li	a5,-1
}
    80005660:	853e                	mv	a0,a5
    80005662:	70b2                	ld	ra,296(sp)
    80005664:	7412                	ld	s0,288(sp)
    80005666:	64f2                	ld	s1,280(sp)
    80005668:	6952                	ld	s2,272(sp)
    8000566a:	6155                	addi	sp,sp,304
    8000566c:	8082                	ret

000000008000566e <sys_unlink>:
{
    8000566e:	7151                	addi	sp,sp,-240
    80005670:	f586                	sd	ra,232(sp)
    80005672:	f1a2                	sd	s0,224(sp)
    80005674:	eda6                	sd	s1,216(sp)
    80005676:	e9ca                	sd	s2,208(sp)
    80005678:	e5ce                	sd	s3,200(sp)
    8000567a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000567c:	08000613          	li	a2,128
    80005680:	f3040593          	addi	a1,s0,-208
    80005684:	4501                	li	a0,0
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	6d6080e7          	jalr	1750(ra) # 80002d5c <argstr>
    8000568e:	18054163          	bltz	a0,80005810 <sys_unlink+0x1a2>
  begin_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	c14080e7          	jalr	-1004(ra) # 800042a6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000569a:	fb040593          	addi	a1,s0,-80
    8000569e:	f3040513          	addi	a0,s0,-208
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	a06080e7          	jalr	-1530(ra) # 800040a8 <nameiparent>
    800056aa:	84aa                	mv	s1,a0
    800056ac:	c979                	beqz	a0,80005782 <sys_unlink+0x114>
  ilock(dp);
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	226080e7          	jalr	550(ra) # 800038d4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b6:	00003597          	auipc	a1,0x3
    800056ba:	05258593          	addi	a1,a1,82 # 80008708 <syscalls+0x2c0>
    800056be:	fb040513          	addi	a0,s0,-80
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	6dc080e7          	jalr	1756(ra) # 80003d9e <namecmp>
    800056ca:	14050a63          	beqz	a0,8000581e <sys_unlink+0x1b0>
    800056ce:	00003597          	auipc	a1,0x3
    800056d2:	04258593          	addi	a1,a1,66 # 80008710 <syscalls+0x2c8>
    800056d6:	fb040513          	addi	a0,s0,-80
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	6c4080e7          	jalr	1732(ra) # 80003d9e <namecmp>
    800056e2:	12050e63          	beqz	a0,8000581e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e6:	f2c40613          	addi	a2,s0,-212
    800056ea:	fb040593          	addi	a1,s0,-80
    800056ee:	8526                	mv	a0,s1
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	6c8080e7          	jalr	1736(ra) # 80003db8 <dirlookup>
    800056f8:	892a                	mv	s2,a0
    800056fa:	12050263          	beqz	a0,8000581e <sys_unlink+0x1b0>
  ilock(ip);
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	1d6080e7          	jalr	470(ra) # 800038d4 <ilock>
  if(ip->nlink < 1)
    80005706:	04a91783          	lh	a5,74(s2)
    8000570a:	08f05263          	blez	a5,8000578e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570e:	04491703          	lh	a4,68(s2)
    80005712:	4785                	li	a5,1
    80005714:	08f70563          	beq	a4,a5,8000579e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005718:	4641                	li	a2,16
    8000571a:	4581                	li	a1,0
    8000571c:	fc040513          	addi	a0,s0,-64
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	5c0080e7          	jalr	1472(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005728:	4741                	li	a4,16
    8000572a:	f2c42683          	lw	a3,-212(s0)
    8000572e:	fc040613          	addi	a2,s0,-64
    80005732:	4581                	li	a1,0
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	54a080e7          	jalr	1354(ra) # 80003c80 <writei>
    8000573e:	47c1                	li	a5,16
    80005740:	0af51563          	bne	a0,a5,800057ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005744:	04491703          	lh	a4,68(s2)
    80005748:	4785                	li	a5,1
    8000574a:	0af70863          	beq	a4,a5,800057fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	3e6080e7          	jalr	998(ra) # 80003b36 <iunlockput>
  ip->nlink--;
    80005758:	04a95783          	lhu	a5,74(s2)
    8000575c:	37fd                	addiw	a5,a5,-1
    8000575e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005762:	854a                	mv	a0,s2
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	0a6080e7          	jalr	166(ra) # 8000380a <iupdate>
  iunlockput(ip);
    8000576c:	854a                	mv	a0,s2
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	3c8080e7          	jalr	968(ra) # 80003b36 <iunlockput>
  end_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	bb0080e7          	jalr	-1104(ra) # 80004326 <end_op>
  return 0;
    8000577e:	4501                	li	a0,0
    80005780:	a84d                	j	80005832 <sys_unlink+0x1c4>
    end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	ba4080e7          	jalr	-1116(ra) # 80004326 <end_op>
    return -1;
    8000578a:	557d                	li	a0,-1
    8000578c:	a05d                	j	80005832 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578e:	00003517          	auipc	a0,0x3
    80005792:	faa50513          	addi	a0,a0,-86 # 80008738 <syscalls+0x2f0>
    80005796:	ffffb097          	auipc	ra,0xffffb
    8000579a:	da8080e7          	jalr	-600(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579e:	04c92703          	lw	a4,76(s2)
    800057a2:	02000793          	li	a5,32
    800057a6:	f6e7f9e3          	bgeu	a5,a4,80005718 <sys_unlink+0xaa>
    800057aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ae:	4741                	li	a4,16
    800057b0:	86ce                	mv	a3,s3
    800057b2:	f1840613          	addi	a2,s0,-232
    800057b6:	4581                	li	a1,0
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	3ce080e7          	jalr	974(ra) # 80003b88 <readi>
    800057c2:	47c1                	li	a5,16
    800057c4:	00f51b63          	bne	a0,a5,800057da <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c8:	f1845783          	lhu	a5,-232(s0)
    800057cc:	e7a1                	bnez	a5,80005814 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ce:	29c1                	addiw	s3,s3,16
    800057d0:	04c92783          	lw	a5,76(s2)
    800057d4:	fcf9ede3          	bltu	s3,a5,800057ae <sys_unlink+0x140>
    800057d8:	b781                	j	80005718 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057da:	00003517          	auipc	a0,0x3
    800057de:	f7650513          	addi	a0,a0,-138 # 80008750 <syscalls+0x308>
    800057e2:	ffffb097          	auipc	ra,0xffffb
    800057e6:	d5c080e7          	jalr	-676(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057ea:	00003517          	auipc	a0,0x3
    800057ee:	f7e50513          	addi	a0,a0,-130 # 80008768 <syscalls+0x320>
    800057f2:	ffffb097          	auipc	ra,0xffffb
    800057f6:	d4c080e7          	jalr	-692(ra) # 8000053e <panic>
    dp->nlink--;
    800057fa:	04a4d783          	lhu	a5,74(s1)
    800057fe:	37fd                	addiw	a5,a5,-1
    80005800:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005804:	8526                	mv	a0,s1
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	004080e7          	jalr	4(ra) # 8000380a <iupdate>
    8000580e:	b781                	j	8000574e <sys_unlink+0xe0>
    return -1;
    80005810:	557d                	li	a0,-1
    80005812:	a005                	j	80005832 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005814:	854a                	mv	a0,s2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	320080e7          	jalr	800(ra) # 80003b36 <iunlockput>
  iunlockput(dp);
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	316080e7          	jalr	790(ra) # 80003b36 <iunlockput>
  end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	afe080e7          	jalr	-1282(ra) # 80004326 <end_op>
  return -1;
    80005830:	557d                	li	a0,-1
}
    80005832:	70ae                	ld	ra,232(sp)
    80005834:	740e                	ld	s0,224(sp)
    80005836:	64ee                	ld	s1,216(sp)
    80005838:	694e                	ld	s2,208(sp)
    8000583a:	69ae                	ld	s3,200(sp)
    8000583c:	616d                	addi	sp,sp,240
    8000583e:	8082                	ret

0000000080005840 <sys_open>:

uint64
sys_open(void)
{
    80005840:	7131                	addi	sp,sp,-192
    80005842:	fd06                	sd	ra,184(sp)
    80005844:	f922                	sd	s0,176(sp)
    80005846:	f526                	sd	s1,168(sp)
    80005848:	f14a                	sd	s2,160(sp)
    8000584a:	ed4e                	sd	s3,152(sp)
    8000584c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000584e:	08000613          	li	a2,128
    80005852:	f5040593          	addi	a1,s0,-176
    80005856:	4501                	li	a0,0
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	504080e7          	jalr	1284(ra) # 80002d5c <argstr>
    return -1;
    80005860:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005862:	0c054163          	bltz	a0,80005924 <sys_open+0xe4>
    80005866:	f4c40593          	addi	a1,s0,-180
    8000586a:	4505                	li	a0,1
    8000586c:	ffffd097          	auipc	ra,0xffffd
    80005870:	4ac080e7          	jalr	1196(ra) # 80002d18 <argint>
    80005874:	0a054863          	bltz	a0,80005924 <sys_open+0xe4>

  begin_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	a2e080e7          	jalr	-1490(ra) # 800042a6 <begin_op>

  if(omode & O_CREATE){
    80005880:	f4c42783          	lw	a5,-180(s0)
    80005884:	2007f793          	andi	a5,a5,512
    80005888:	cbdd                	beqz	a5,8000593e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000588a:	4681                	li	a3,0
    8000588c:	4601                	li	a2,0
    8000588e:	4589                	li	a1,2
    80005890:	f5040513          	addi	a0,s0,-176
    80005894:	00000097          	auipc	ra,0x0
    80005898:	972080e7          	jalr	-1678(ra) # 80005206 <create>
    8000589c:	892a                	mv	s2,a0
    if(ip == 0){
    8000589e:	c959                	beqz	a0,80005934 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058a0:	04491703          	lh	a4,68(s2)
    800058a4:	478d                	li	a5,3
    800058a6:	00f71763          	bne	a4,a5,800058b4 <sys_open+0x74>
    800058aa:	04695703          	lhu	a4,70(s2)
    800058ae:	47a5                	li	a5,9
    800058b0:	0ce7ec63          	bltu	a5,a4,80005988 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	e02080e7          	jalr	-510(ra) # 800046b6 <filealloc>
    800058bc:	89aa                	mv	s3,a0
    800058be:	10050263          	beqz	a0,800059c2 <sys_open+0x182>
    800058c2:	00000097          	auipc	ra,0x0
    800058c6:	902080e7          	jalr	-1790(ra) # 800051c4 <fdalloc>
    800058ca:	84aa                	mv	s1,a0
    800058cc:	0e054663          	bltz	a0,800059b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058d0:	04491703          	lh	a4,68(s2)
    800058d4:	478d                	li	a5,3
    800058d6:	0cf70463          	beq	a4,a5,8000599e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058da:	4789                	li	a5,2
    800058dc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058e0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e8:	f4c42783          	lw	a5,-180(s0)
    800058ec:	0017c713          	xori	a4,a5,1
    800058f0:	8b05                	andi	a4,a4,1
    800058f2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f6:	0037f713          	andi	a4,a5,3
    800058fa:	00e03733          	snez	a4,a4
    800058fe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005902:	4007f793          	andi	a5,a5,1024
    80005906:	c791                	beqz	a5,80005912 <sys_open+0xd2>
    80005908:	04491703          	lh	a4,68(s2)
    8000590c:	4789                	li	a5,2
    8000590e:	08f70f63          	beq	a4,a5,800059ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005912:	854a                	mv	a0,s2
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	082080e7          	jalr	130(ra) # 80003996 <iunlock>
  end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	a0a080e7          	jalr	-1526(ra) # 80004326 <end_op>

  return fd;
}
    80005924:	8526                	mv	a0,s1
    80005926:	70ea                	ld	ra,184(sp)
    80005928:	744a                	ld	s0,176(sp)
    8000592a:	74aa                	ld	s1,168(sp)
    8000592c:	790a                	ld	s2,160(sp)
    8000592e:	69ea                	ld	s3,152(sp)
    80005930:	6129                	addi	sp,sp,192
    80005932:	8082                	ret
      end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	9f2080e7          	jalr	-1550(ra) # 80004326 <end_op>
      return -1;
    8000593c:	b7e5                	j	80005924 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593e:	f5040513          	addi	a0,s0,-176
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	748080e7          	jalr	1864(ra) # 8000408a <namei>
    8000594a:	892a                	mv	s2,a0
    8000594c:	c905                	beqz	a0,8000597c <sys_open+0x13c>
    ilock(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	f86080e7          	jalr	-122(ra) # 800038d4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005956:	04491703          	lh	a4,68(s2)
    8000595a:	4785                	li	a5,1
    8000595c:	f4f712e3          	bne	a4,a5,800058a0 <sys_open+0x60>
    80005960:	f4c42783          	lw	a5,-180(s0)
    80005964:	dba1                	beqz	a5,800058b4 <sys_open+0x74>
      iunlockput(ip);
    80005966:	854a                	mv	a0,s2
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	1ce080e7          	jalr	462(ra) # 80003b36 <iunlockput>
      end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	9b6080e7          	jalr	-1610(ra) # 80004326 <end_op>
      return -1;
    80005978:	54fd                	li	s1,-1
    8000597a:	b76d                	j	80005924 <sys_open+0xe4>
      end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	9aa080e7          	jalr	-1622(ra) # 80004326 <end_op>
      return -1;
    80005984:	54fd                	li	s1,-1
    80005986:	bf79                	j	80005924 <sys_open+0xe4>
    iunlockput(ip);
    80005988:	854a                	mv	a0,s2
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	1ac080e7          	jalr	428(ra) # 80003b36 <iunlockput>
    end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	994080e7          	jalr	-1644(ra) # 80004326 <end_op>
    return -1;
    8000599a:	54fd                	li	s1,-1
    8000599c:	b761                	j	80005924 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059a2:	04691783          	lh	a5,70(s2)
    800059a6:	02f99223          	sh	a5,36(s3)
    800059aa:	bf2d                	j	800058e4 <sys_open+0xa4>
    itrunc(ip);
    800059ac:	854a                	mv	a0,s2
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	034080e7          	jalr	52(ra) # 800039e2 <itrunc>
    800059b6:	bfb1                	j	80005912 <sys_open+0xd2>
      fileclose(f);
    800059b8:	854e                	mv	a0,s3
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	db8080e7          	jalr	-584(ra) # 80004772 <fileclose>
    iunlockput(ip);
    800059c2:	854a                	mv	a0,s2
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	172080e7          	jalr	370(ra) # 80003b36 <iunlockput>
    end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	95a080e7          	jalr	-1702(ra) # 80004326 <end_op>
    return -1;
    800059d4:	54fd                	li	s1,-1
    800059d6:	b7b9                	j	80005924 <sys_open+0xe4>

00000000800059d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d8:	7175                	addi	sp,sp,-144
    800059da:	e506                	sd	ra,136(sp)
    800059dc:	e122                	sd	s0,128(sp)
    800059de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	8c6080e7          	jalr	-1850(ra) # 800042a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e8:	08000613          	li	a2,128
    800059ec:	f7040593          	addi	a1,s0,-144
    800059f0:	4501                	li	a0,0
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	36a080e7          	jalr	874(ra) # 80002d5c <argstr>
    800059fa:	02054963          	bltz	a0,80005a2c <sys_mkdir+0x54>
    800059fe:	4681                	li	a3,0
    80005a00:	4601                	li	a2,0
    80005a02:	4585                	li	a1,1
    80005a04:	f7040513          	addi	a0,s0,-144
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	7fe080e7          	jalr	2046(ra) # 80005206 <create>
    80005a10:	cd11                	beqz	a0,80005a2c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	124080e7          	jalr	292(ra) # 80003b36 <iunlockput>
  end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	90c080e7          	jalr	-1780(ra) # 80004326 <end_op>
  return 0;
    80005a22:	4501                	li	a0,0
}
    80005a24:	60aa                	ld	ra,136(sp)
    80005a26:	640a                	ld	s0,128(sp)
    80005a28:	6149                	addi	sp,sp,144
    80005a2a:	8082                	ret
    end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	8fa080e7          	jalr	-1798(ra) # 80004326 <end_op>
    return -1;
    80005a34:	557d                	li	a0,-1
    80005a36:	b7fd                	j	80005a24 <sys_mkdir+0x4c>

0000000080005a38 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a38:	7135                	addi	sp,sp,-160
    80005a3a:	ed06                	sd	ra,152(sp)
    80005a3c:	e922                	sd	s0,144(sp)
    80005a3e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	866080e7          	jalr	-1946(ra) # 800042a6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a48:	08000613          	li	a2,128
    80005a4c:	f7040593          	addi	a1,s0,-144
    80005a50:	4501                	li	a0,0
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	30a080e7          	jalr	778(ra) # 80002d5c <argstr>
    80005a5a:	04054a63          	bltz	a0,80005aae <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a5e:	f6c40593          	addi	a1,s0,-148
    80005a62:	4505                	li	a0,1
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	2b4080e7          	jalr	692(ra) # 80002d18 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a6c:	04054163          	bltz	a0,80005aae <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a70:	f6840593          	addi	a1,s0,-152
    80005a74:	4509                	li	a0,2
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	2a2080e7          	jalr	674(ra) # 80002d18 <argint>
     argint(1, &major) < 0 ||
    80005a7e:	02054863          	bltz	a0,80005aae <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a82:	f6841683          	lh	a3,-152(s0)
    80005a86:	f6c41603          	lh	a2,-148(s0)
    80005a8a:	458d                	li	a1,3
    80005a8c:	f7040513          	addi	a0,s0,-144
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	776080e7          	jalr	1910(ra) # 80005206 <create>
     argint(2, &minor) < 0 ||
    80005a98:	c919                	beqz	a0,80005aae <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	09c080e7          	jalr	156(ra) # 80003b36 <iunlockput>
  end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	884080e7          	jalr	-1916(ra) # 80004326 <end_op>
  return 0;
    80005aaa:	4501                	li	a0,0
    80005aac:	a031                	j	80005ab8 <sys_mknod+0x80>
    end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	878080e7          	jalr	-1928(ra) # 80004326 <end_op>
    return -1;
    80005ab6:	557d                	li	a0,-1
}
    80005ab8:	60ea                	ld	ra,152(sp)
    80005aba:	644a                	ld	s0,144(sp)
    80005abc:	610d                	addi	sp,sp,160
    80005abe:	8082                	ret

0000000080005ac0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ac0:	7135                	addi	sp,sp,-160
    80005ac2:	ed06                	sd	ra,152(sp)
    80005ac4:	e922                	sd	s0,144(sp)
    80005ac6:	e526                	sd	s1,136(sp)
    80005ac8:	e14a                	sd	s2,128(sp)
    80005aca:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005acc:	ffffc097          	auipc	ra,0xffffc
    80005ad0:	ef4080e7          	jalr	-268(ra) # 800019c0 <myproc>
    80005ad4:	892a                	mv	s2,a0
  
  begin_op();
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	7d0080e7          	jalr	2000(ra) # 800042a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ade:	08000613          	li	a2,128
    80005ae2:	f6040593          	addi	a1,s0,-160
    80005ae6:	4501                	li	a0,0
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	274080e7          	jalr	628(ra) # 80002d5c <argstr>
    80005af0:	04054b63          	bltz	a0,80005b46 <sys_chdir+0x86>
    80005af4:	f6040513          	addi	a0,s0,-160
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	592080e7          	jalr	1426(ra) # 8000408a <namei>
    80005b00:	84aa                	mv	s1,a0
    80005b02:	c131                	beqz	a0,80005b46 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	dd0080e7          	jalr	-560(ra) # 800038d4 <ilock>
  if(ip->type != T_DIR){
    80005b0c:	04449703          	lh	a4,68(s1)
    80005b10:	4785                	li	a5,1
    80005b12:	04f71063          	bne	a4,a5,80005b52 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b16:	8526                	mv	a0,s1
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	e7e080e7          	jalr	-386(ra) # 80003996 <iunlock>
  iput(p->cwd);
    80005b20:	17893503          	ld	a0,376(s2)
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	f6a080e7          	jalr	-150(ra) # 80003a8e <iput>
  end_op();
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	7fa080e7          	jalr	2042(ra) # 80004326 <end_op>
  p->cwd = ip;
    80005b34:	16993c23          	sd	s1,376(s2)
  return 0;
    80005b38:	4501                	li	a0,0
}
    80005b3a:	60ea                	ld	ra,152(sp)
    80005b3c:	644a                	ld	s0,144(sp)
    80005b3e:	64aa                	ld	s1,136(sp)
    80005b40:	690a                	ld	s2,128(sp)
    80005b42:	610d                	addi	sp,sp,160
    80005b44:	8082                	ret
    end_op();
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	7e0080e7          	jalr	2016(ra) # 80004326 <end_op>
    return -1;
    80005b4e:	557d                	li	a0,-1
    80005b50:	b7ed                	j	80005b3a <sys_chdir+0x7a>
    iunlockput(ip);
    80005b52:	8526                	mv	a0,s1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	fe2080e7          	jalr	-30(ra) # 80003b36 <iunlockput>
    end_op();
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	7ca080e7          	jalr	1994(ra) # 80004326 <end_op>
    return -1;
    80005b64:	557d                	li	a0,-1
    80005b66:	bfd1                	j	80005b3a <sys_chdir+0x7a>

0000000080005b68 <sys_exec>:

uint64
sys_exec(void)
{
    80005b68:	7145                	addi	sp,sp,-464
    80005b6a:	e786                	sd	ra,456(sp)
    80005b6c:	e3a2                	sd	s0,448(sp)
    80005b6e:	ff26                	sd	s1,440(sp)
    80005b70:	fb4a                	sd	s2,432(sp)
    80005b72:	f74e                	sd	s3,424(sp)
    80005b74:	f352                	sd	s4,416(sp)
    80005b76:	ef56                	sd	s5,408(sp)
    80005b78:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b7a:	08000613          	li	a2,128
    80005b7e:	f4040593          	addi	a1,s0,-192
    80005b82:	4501                	li	a0,0
    80005b84:	ffffd097          	auipc	ra,0xffffd
    80005b88:	1d8080e7          	jalr	472(ra) # 80002d5c <argstr>
    return -1;
    80005b8c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b8e:	0c054a63          	bltz	a0,80005c62 <sys_exec+0xfa>
    80005b92:	e3840593          	addi	a1,s0,-456
    80005b96:	4505                	li	a0,1
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	1a2080e7          	jalr	418(ra) # 80002d3a <argaddr>
    80005ba0:	0c054163          	bltz	a0,80005c62 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba4:	10000613          	li	a2,256
    80005ba8:	4581                	li	a1,0
    80005baa:	e4040513          	addi	a0,s0,-448
    80005bae:	ffffb097          	auipc	ra,0xffffb
    80005bb2:	132080e7          	jalr	306(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bba:	89a6                	mv	s3,s1
    80005bbc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bbe:	02000a13          	li	s4,32
    80005bc2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc6:	00391513          	slli	a0,s2,0x3
    80005bca:	e3040593          	addi	a1,s0,-464
    80005bce:	e3843783          	ld	a5,-456(s0)
    80005bd2:	953e                	add	a0,a0,a5
    80005bd4:	ffffd097          	auipc	ra,0xffffd
    80005bd8:	0aa080e7          	jalr	170(ra) # 80002c7e <fetchaddr>
    80005bdc:	02054a63          	bltz	a0,80005c10 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005be0:	e3043783          	ld	a5,-464(s0)
    80005be4:	c3b9                	beqz	a5,80005c2a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be6:	ffffb097          	auipc	ra,0xffffb
    80005bea:	f0e080e7          	jalr	-242(ra) # 80000af4 <kalloc>
    80005bee:	85aa                	mv	a1,a0
    80005bf0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf4:	cd11                	beqz	a0,80005c10 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf6:	6605                	lui	a2,0x1
    80005bf8:	e3043503          	ld	a0,-464(s0)
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	0d4080e7          	jalr	212(ra) # 80002cd0 <fetchstr>
    80005c04:	00054663          	bltz	a0,80005c10 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c08:	0905                	addi	s2,s2,1
    80005c0a:	09a1                	addi	s3,s3,8
    80005c0c:	fb491be3          	bne	s2,s4,80005bc2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c10:	10048913          	addi	s2,s1,256
    80005c14:	6088                	ld	a0,0(s1)
    80005c16:	c529                	beqz	a0,80005c60 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c18:	ffffb097          	auipc	ra,0xffffb
    80005c1c:	de0080e7          	jalr	-544(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c20:	04a1                	addi	s1,s1,8
    80005c22:	ff2499e3          	bne	s1,s2,80005c14 <sys_exec+0xac>
  return -1;
    80005c26:	597d                	li	s2,-1
    80005c28:	a82d                	j	80005c62 <sys_exec+0xfa>
      argv[i] = 0;
    80005c2a:	0a8e                	slli	s5,s5,0x3
    80005c2c:	fc040793          	addi	a5,s0,-64
    80005c30:	9abe                	add	s5,s5,a5
    80005c32:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c36:	e4040593          	addi	a1,s0,-448
    80005c3a:	f4040513          	addi	a0,s0,-192
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	194080e7          	jalr	404(ra) # 80004dd2 <exec>
    80005c46:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c48:	10048993          	addi	s3,s1,256
    80005c4c:	6088                	ld	a0,0(s1)
    80005c4e:	c911                	beqz	a0,80005c62 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c50:	ffffb097          	auipc	ra,0xffffb
    80005c54:	da8080e7          	jalr	-600(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c58:	04a1                	addi	s1,s1,8
    80005c5a:	ff3499e3          	bne	s1,s3,80005c4c <sys_exec+0xe4>
    80005c5e:	a011                	j	80005c62 <sys_exec+0xfa>
  return -1;
    80005c60:	597d                	li	s2,-1
}
    80005c62:	854a                	mv	a0,s2
    80005c64:	60be                	ld	ra,456(sp)
    80005c66:	641e                	ld	s0,448(sp)
    80005c68:	74fa                	ld	s1,440(sp)
    80005c6a:	795a                	ld	s2,432(sp)
    80005c6c:	79ba                	ld	s3,424(sp)
    80005c6e:	7a1a                	ld	s4,416(sp)
    80005c70:	6afa                	ld	s5,408(sp)
    80005c72:	6179                	addi	sp,sp,464
    80005c74:	8082                	ret

0000000080005c76 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c76:	7139                	addi	sp,sp,-64
    80005c78:	fc06                	sd	ra,56(sp)
    80005c7a:	f822                	sd	s0,48(sp)
    80005c7c:	f426                	sd	s1,40(sp)
    80005c7e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c80:	ffffc097          	auipc	ra,0xffffc
    80005c84:	d40080e7          	jalr	-704(ra) # 800019c0 <myproc>
    80005c88:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c8a:	fd840593          	addi	a1,s0,-40
    80005c8e:	4501                	li	a0,0
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	0aa080e7          	jalr	170(ra) # 80002d3a <argaddr>
    return -1;
    80005c98:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c9a:	0e054063          	bltz	a0,80005d7a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c9e:	fc840593          	addi	a1,s0,-56
    80005ca2:	fd040513          	addi	a0,s0,-48
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	dfc080e7          	jalr	-516(ra) # 80004aa2 <pipealloc>
    return -1;
    80005cae:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cb0:	0c054563          	bltz	a0,80005d7a <sys_pipe+0x104>
  fd0 = -1;
    80005cb4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb8:	fd043503          	ld	a0,-48(s0)
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	508080e7          	jalr	1288(ra) # 800051c4 <fdalloc>
    80005cc4:	fca42223          	sw	a0,-60(s0)
    80005cc8:	08054c63          	bltz	a0,80005d60 <sys_pipe+0xea>
    80005ccc:	fc843503          	ld	a0,-56(s0)
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	4f4080e7          	jalr	1268(ra) # 800051c4 <fdalloc>
    80005cd8:	fca42023          	sw	a0,-64(s0)
    80005cdc:	06054863          	bltz	a0,80005d4c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ce0:	4691                	li	a3,4
    80005ce2:	fc440613          	addi	a2,s0,-60
    80005ce6:	fd843583          	ld	a1,-40(s0)
    80005cea:	7ca8                	ld	a0,120(s1)
    80005cec:	ffffc097          	auipc	ra,0xffffc
    80005cf0:	986080e7          	jalr	-1658(ra) # 80001672 <copyout>
    80005cf4:	02054063          	bltz	a0,80005d14 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf8:	4691                	li	a3,4
    80005cfa:	fc040613          	addi	a2,s0,-64
    80005cfe:	fd843583          	ld	a1,-40(s0)
    80005d02:	0591                	addi	a1,a1,4
    80005d04:	7ca8                	ld	a0,120(s1)
    80005d06:	ffffc097          	auipc	ra,0xffffc
    80005d0a:	96c080e7          	jalr	-1684(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d0e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d10:	06055563          	bgez	a0,80005d7a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d14:	fc442783          	lw	a5,-60(s0)
    80005d18:	07f9                	addi	a5,a5,30
    80005d1a:	078e                	slli	a5,a5,0x3
    80005d1c:	97a6                	add	a5,a5,s1
    80005d1e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d22:	fc042503          	lw	a0,-64(s0)
    80005d26:	0579                	addi	a0,a0,30
    80005d28:	050e                	slli	a0,a0,0x3
    80005d2a:	9526                	add	a0,a0,s1
    80005d2c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d30:	fd043503          	ld	a0,-48(s0)
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	a3e080e7          	jalr	-1474(ra) # 80004772 <fileclose>
    fileclose(wf);
    80005d3c:	fc843503          	ld	a0,-56(s0)
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	a32080e7          	jalr	-1486(ra) # 80004772 <fileclose>
    return -1;
    80005d48:	57fd                	li	a5,-1
    80005d4a:	a805                	j	80005d7a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d4c:	fc442783          	lw	a5,-60(s0)
    80005d50:	0007c863          	bltz	a5,80005d60 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d54:	01e78513          	addi	a0,a5,30
    80005d58:	050e                	slli	a0,a0,0x3
    80005d5a:	9526                	add	a0,a0,s1
    80005d5c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d60:	fd043503          	ld	a0,-48(s0)
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	a0e080e7          	jalr	-1522(ra) # 80004772 <fileclose>
    fileclose(wf);
    80005d6c:	fc843503          	ld	a0,-56(s0)
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	a02080e7          	jalr	-1534(ra) # 80004772 <fileclose>
    return -1;
    80005d78:	57fd                	li	a5,-1
}
    80005d7a:	853e                	mv	a0,a5
    80005d7c:	70e2                	ld	ra,56(sp)
    80005d7e:	7442                	ld	s0,48(sp)
    80005d80:	74a2                	ld	s1,40(sp)
    80005d82:	6121                	addi	sp,sp,64
    80005d84:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	d7bfc0ef          	jal	ra,80002b4a <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b2c080e7          	jalr	-1236(ra) # 80001994 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	af4080e7          	jalr	-1292(ra) # 80001994 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	acc080e7          	jalr	-1332(ra) # 80001994 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	06a7c963          	blt	a5,a0,80005f62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	10c78793          	addi	a5,a5,268 # 80023000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	e7ad                	bnez	a5,80005f72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451793          	slli	a5,a0,0x4
    80005f0e:	0001f717          	auipc	a4,0x1f
    80005f12:	0f270713          	addi	a4,a4,242 # 80025000 <disk+0x2000>
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f1e:	6314                	ld	a3,0(a4)
    80005f20:	96be                	add	a3,a3,a5
    80005f22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f26:	6314                	ld	a3,0(a4)
    80005f28:	96be                	add	a3,a3,a5
    80005f2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f2e:	6318                	ld	a4,0(a4)
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f36:	0001d797          	auipc	a5,0x1d
    80005f3a:	0ca78793          	addi	a5,a5,202 # 80023000 <disk>
    80005f3e:	97aa                	add	a5,a5,a0
    80005f40:	6509                	lui	a0,0x2
    80005f42:	953e                	add	a0,a0,a5
    80005f44:	4785                	li	a5,1
    80005f46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f4a:	0001f517          	auipc	a0,0x1f
    80005f4e:	0ce50513          	addi	a0,a0,206 # 80025018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	55a080e7          	jalr	1370(ra) # 800024ac <wakeup>
}
    80005f5a:	60a2                	ld	ra,8(sp)
    80005f5c:	6402                	ld	s0,0(sp)
    80005f5e:	0141                	addi	sp,sp,16
    80005f60:	8082                	ret
    panic("free_desc 1");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	81650513          	addi	a0,a0,-2026 # 80008778 <syscalls+0x330>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	81650513          	addi	a0,a0,-2026 # 80008788 <syscalls+0x340>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>

0000000080005f82 <virtio_disk_init>:
{
    80005f82:	1101                	addi	sp,sp,-32
    80005f84:	ec06                	sd	ra,24(sp)
    80005f86:	e822                	sd	s0,16(sp)
    80005f88:	e426                	sd	s1,8(sp)
    80005f8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f8c:	00003597          	auipc	a1,0x3
    80005f90:	80c58593          	addi	a1,a1,-2036 # 80008798 <syscalls+0x350>
    80005f94:	0001f517          	auipc	a0,0x1f
    80005f98:	19450513          	addi	a0,a0,404 # 80025128 <disk+0x2128>
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	bb8080e7          	jalr	-1096(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa4:	100017b7          	lui	a5,0x10001
    80005fa8:	4398                	lw	a4,0(a5)
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	747277b7          	lui	a5,0x74727
    80005fb0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fb4:	0ef71163          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	43dc                	lw	a5,4(a5)
    80005fbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc0:	4705                	li	a4,1
    80005fc2:	0ce79a63          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc6:	100017b7          	lui	a5,0x10001
    80005fca:	479c                	lw	a5,8(a5)
    80005fcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fce:	4709                	li	a4,2
    80005fd0:	0ce79363          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fd4:	100017b7          	lui	a5,0x10001
    80005fd8:	47d8                	lw	a4,12(a5)
    80005fda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fdc:	554d47b7          	lui	a5,0x554d4
    80005fe0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fe4:	0af71963          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	4705                	li	a4,1
    80005fee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff0:	470d                	li	a4,3
    80005ff2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ff4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ff6:	c7ffe737          	lui	a4,0xc7ffe
    80005ffa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ffe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006000:	2701                	sext.w	a4,a4
    80006002:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	472d                	li	a4,11
    80006006:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	473d                	li	a4,15
    8000600a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000600c:	6705                	lui	a4,0x1
    8000600e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006010:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006014:	5bdc                	lw	a5,52(a5)
    80006016:	2781                	sext.w	a5,a5
  if(max == 0)
    80006018:	c7d9                	beqz	a5,800060a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	08f77d63          	bgeu	a4,a5,800060b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006020:	100014b7          	lui	s1,0x10001
    80006024:	47a1                	li	a5,8
    80006026:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006028:	6609                	lui	a2,0x2
    8000602a:	4581                	li	a1,0
    8000602c:	0001d517          	auipc	a0,0x1d
    80006030:	fd450513          	addi	a0,a0,-44 # 80023000 <disk>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	cac080e7          	jalr	-852(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000603c:	0001d717          	auipc	a4,0x1d
    80006040:	fc470713          	addi	a4,a4,-60 # 80023000 <disk>
    80006044:	00c75793          	srli	a5,a4,0xc
    80006048:	2781                	sext.w	a5,a5
    8000604a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000604c:	0001f797          	auipc	a5,0x1f
    80006050:	fb478793          	addi	a5,a5,-76 # 80025000 <disk+0x2000>
    80006054:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006056:	0001d717          	auipc	a4,0x1d
    8000605a:	02a70713          	addi	a4,a4,42 # 80023080 <disk+0x80>
    8000605e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006060:	0001e717          	auipc	a4,0x1e
    80006064:	fa070713          	addi	a4,a4,-96 # 80024000 <disk+0x1000>
    80006068:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
    80006070:	00e78ca3          	sb	a4,25(a5)
    80006074:	00e78d23          	sb	a4,26(a5)
    80006078:	00e78da3          	sb	a4,27(a5)
    8000607c:	00e78e23          	sb	a4,28(a5)
    80006080:	00e78ea3          	sb	a4,29(a5)
    80006084:	00e78f23          	sb	a4,30(a5)
    80006088:	00e78fa3          	sb	a4,31(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret
    panic("could not find virtio disk");
    80006096:	00002517          	auipc	a0,0x2
    8000609a:	71250513          	addi	a0,a0,1810 # 800087a8 <syscalls+0x360>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	72250513          	addi	a0,a0,1826 # 800087c8 <syscalls+0x380>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	73250513          	addi	a0,a0,1842 # 800087e8 <syscalls+0x3a0>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>

00000000800060c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c6:	7159                	addi	sp,sp,-112
    800060c8:	f486                	sd	ra,104(sp)
    800060ca:	f0a2                	sd	s0,96(sp)
    800060cc:	eca6                	sd	s1,88(sp)
    800060ce:	e8ca                	sd	s2,80(sp)
    800060d0:	e4ce                	sd	s3,72(sp)
    800060d2:	e0d2                	sd	s4,64(sp)
    800060d4:	fc56                	sd	s5,56(sp)
    800060d6:	f85a                	sd	s6,48(sp)
    800060d8:	f45e                	sd	s7,40(sp)
    800060da:	f062                	sd	s8,32(sp)
    800060dc:	ec66                	sd	s9,24(sp)
    800060de:	e86a                	sd	s10,16(sp)
    800060e0:	1880                	addi	s0,sp,112
    800060e2:	892a                	mv	s2,a0
    800060e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e6:	00c52c83          	lw	s9,12(a0)
    800060ea:	001c9c9b          	slliw	s9,s9,0x1
    800060ee:	1c82                	slli	s9,s9,0x20
    800060f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f4:	0001f517          	auipc	a0,0x1f
    800060f8:	03450513          	addi	a0,a0,52 # 80025128 <disk+0x2128>
    800060fc:	ffffb097          	auipc	ra,0xffffb
    80006100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006104:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006106:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006108:	0001db97          	auipc	s7,0x1d
    8000610c:	ef8b8b93          	addi	s7,s7,-264 # 80023000 <disk>
    80006110:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006112:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006114:	8a4e                	mv	s4,s3
    80006116:	a051                	j	8000619a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006118:	00fb86b3          	add	a3,s7,a5
    8000611c:	96da                	add	a3,a3,s6
    8000611e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006122:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006124:	0207c563          	bltz	a5,8000614e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006128:	2485                	addiw	s1,s1,1
    8000612a:	0711                	addi	a4,a4,4
    8000612c:	25548063          	beq	s1,s5,8000636c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006130:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006132:	0001f697          	auipc	a3,0x1f
    80006136:	ee668693          	addi	a3,a3,-282 # 80025018 <disk+0x2018>
    8000613a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000613c:	0006c583          	lbu	a1,0(a3)
    80006140:	fde1                	bnez	a1,80006118 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006142:	2785                	addiw	a5,a5,1
    80006144:	0685                	addi	a3,a3,1
    80006146:	ff879be3          	bne	a5,s8,8000613c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000614a:	57fd                	li	a5,-1
    8000614c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000614e:	02905a63          	blez	s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006152:	f9042503          	lw	a0,-112(s0)
    80006156:	00000097          	auipc	ra,0x0
    8000615a:	d90080e7          	jalr	-624(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    8000615e:	4785                	li	a5,1
    80006160:	0297d163          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006164:	f9442503          	lw	a0,-108(s0)
    80006168:	00000097          	auipc	ra,0x0
    8000616c:	d7e080e7          	jalr	-642(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006170:	4789                	li	a5,2
    80006172:	0097d863          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006176:	f9842503          	lw	a0,-104(s0)
    8000617a:	00000097          	auipc	ra,0x0
    8000617e:	d6c080e7          	jalr	-660(ra) # 80005ee6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006182:	0001f597          	auipc	a1,0x1f
    80006186:	fa658593          	addi	a1,a1,-90 # 80025128 <disk+0x2128>
    8000618a:	0001f517          	auipc	a0,0x1f
    8000618e:	e8e50513          	addi	a0,a0,-370 # 80025018 <disk+0x2018>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	182080e7          	jalr	386(ra) # 80002314 <sleep>
  for(int i = 0; i < 3; i++){
    8000619a:	f9040713          	addi	a4,s0,-112
    8000619e:	84ce                	mv	s1,s3
    800061a0:	bf41                	j	80006130 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061a2:	20058713          	addi	a4,a1,512
    800061a6:	00471693          	slli	a3,a4,0x4
    800061aa:	0001d717          	auipc	a4,0x1d
    800061ae:	e5670713          	addi	a4,a4,-426 # 80023000 <disk>
    800061b2:	9736                	add	a4,a4,a3
    800061b4:	4685                	li	a3,1
    800061b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061ba:	20058713          	addi	a4,a1,512
    800061be:	00471693          	slli	a3,a4,0x4
    800061c2:	0001d717          	auipc	a4,0x1d
    800061c6:	e3e70713          	addi	a4,a4,-450 # 80023000 <disk>
    800061ca:	9736                	add	a4,a4,a3
    800061cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d4:	7679                	lui	a2,0xffffe
    800061d6:	963e                	add	a2,a2,a5
    800061d8:	0001f697          	auipc	a3,0x1f
    800061dc:	e2868693          	addi	a3,a3,-472 # 80025000 <disk+0x2000>
    800061e0:	6298                	ld	a4,0(a3)
    800061e2:	9732                	add	a4,a4,a2
    800061e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061e6:	6298                	ld	a4,0(a3)
    800061e8:	9732                	add	a4,a4,a2
    800061ea:	4541                	li	a0,16
    800061ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ee:	6298                	ld	a4,0(a3)
    800061f0:	9732                	add	a4,a4,a2
    800061f2:	4505                	li	a0,1
    800061f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061f8:	f9442703          	lw	a4,-108(s0)
    800061fc:	6288                	ld	a0,0(a3)
    800061fe:	962a                	add	a2,a2,a0
    80006200:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	6290                	ld	a2,0(a3)
    80006208:	963a                	add	a2,a2,a4
    8000620a:	05890513          	addi	a0,s2,88
    8000620e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006210:	6294                	ld	a3,0(a3)
    80006212:	96ba                	add	a3,a3,a4
    80006214:	40000613          	li	a2,1024
    80006218:	c690                	sw	a2,8(a3)
  if(write)
    8000621a:	140d0063          	beqz	s10,8000635a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000621e:	0001f697          	auipc	a3,0x1f
    80006222:	de26b683          	ld	a3,-542(a3) # 80025000 <disk+0x2000>
    80006226:	96ba                	add	a3,a3,a4
    80006228:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000622c:	0001d817          	auipc	a6,0x1d
    80006230:	dd480813          	addi	a6,a6,-556 # 80023000 <disk>
    80006234:	0001f517          	auipc	a0,0x1f
    80006238:	dcc50513          	addi	a0,a0,-564 # 80025000 <disk+0x2000>
    8000623c:	6114                	ld	a3,0(a0)
    8000623e:	96ba                	add	a3,a3,a4
    80006240:	00c6d603          	lhu	a2,12(a3)
    80006244:	00166613          	ori	a2,a2,1
    80006248:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000624c:	f9842683          	lw	a3,-104(s0)
    80006250:	6110                	ld	a2,0(a0)
    80006252:	9732                	add	a4,a4,a2
    80006254:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006258:	20058613          	addi	a2,a1,512
    8000625c:	0612                	slli	a2,a2,0x4
    8000625e:	9642                	add	a2,a2,a6
    80006260:	577d                	li	a4,-1
    80006262:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006266:	00469713          	slli	a4,a3,0x4
    8000626a:	6114                	ld	a3,0(a0)
    8000626c:	96ba                	add	a3,a3,a4
    8000626e:	03078793          	addi	a5,a5,48
    80006272:	97c2                	add	a5,a5,a6
    80006274:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006276:	611c                	ld	a5,0(a0)
    80006278:	97ba                	add	a5,a5,a4
    8000627a:	4685                	li	a3,1
    8000627c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000627e:	611c                	ld	a5,0(a0)
    80006280:	97ba                	add	a5,a5,a4
    80006282:	4809                	li	a6,2
    80006284:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006288:	611c                	ld	a5,0(a0)
    8000628a:	973e                	add	a4,a4,a5
    8000628c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006290:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006294:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006298:	6518                	ld	a4,8(a0)
    8000629a:	00275783          	lhu	a5,2(a4)
    8000629e:	8b9d                	andi	a5,a5,7
    800062a0:	0786                	slli	a5,a5,0x1
    800062a2:	97ba                	add	a5,a5,a4
    800062a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062ac:	6518                	ld	a4,8(a0)
    800062ae:	00275783          	lhu	a5,2(a4)
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c4:	00492703          	lw	a4,4(s2)
    800062c8:	4785                	li	a5,1
    800062ca:	02f71163          	bne	a4,a5,800062ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ce:	0001f997          	auipc	s3,0x1f
    800062d2:	e5a98993          	addi	s3,s3,-422 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062d8:	85ce                	mv	a1,s3
    800062da:	854a                	mv	a0,s2
    800062dc:	ffffc097          	auipc	ra,0xffffc
    800062e0:	038080e7          	jalr	56(ra) # 80002314 <sleep>
  while(b->disk == 1) {
    800062e4:	00492783          	lw	a5,4(s2)
    800062e8:	fe9788e3          	beq	a5,s1,800062d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062ec:	f9042903          	lw	s2,-112(s0)
    800062f0:	20090793          	addi	a5,s2,512
    800062f4:	00479713          	slli	a4,a5,0x4
    800062f8:	0001d797          	auipc	a5,0x1d
    800062fc:	d0878793          	addi	a5,a5,-760 # 80023000 <disk>
    80006300:	97ba                	add	a5,a5,a4
    80006302:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006306:	0001f997          	auipc	s3,0x1f
    8000630a:	cfa98993          	addi	s3,s3,-774 # 80025000 <disk+0x2000>
    8000630e:	00491713          	slli	a4,s2,0x4
    80006312:	0009b783          	ld	a5,0(s3)
    80006316:	97ba                	add	a5,a5,a4
    80006318:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000631c:	854a                	mv	a0,s2
    8000631e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006322:	00000097          	auipc	ra,0x0
    80006326:	bc4080e7          	jalr	-1084(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000632a:	8885                	andi	s1,s1,1
    8000632c:	f0ed                	bnez	s1,8000630e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000632e:	0001f517          	auipc	a0,0x1f
    80006332:	dfa50513          	addi	a0,a0,-518 # 80025128 <disk+0x2128>
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000633e:	70a6                	ld	ra,104(sp)
    80006340:	7406                	ld	s0,96(sp)
    80006342:	64e6                	ld	s1,88(sp)
    80006344:	6946                	ld	s2,80(sp)
    80006346:	69a6                	ld	s3,72(sp)
    80006348:	6a06                	ld	s4,64(sp)
    8000634a:	7ae2                	ld	s5,56(sp)
    8000634c:	7b42                	ld	s6,48(sp)
    8000634e:	7ba2                	ld	s7,40(sp)
    80006350:	7c02                	ld	s8,32(sp)
    80006352:	6ce2                	ld	s9,24(sp)
    80006354:	6d42                	ld	s10,16(sp)
    80006356:	6165                	addi	sp,sp,112
    80006358:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000635a:	0001f697          	auipc	a3,0x1f
    8000635e:	ca66b683          	ld	a3,-858(a3) # 80025000 <disk+0x2000>
    80006362:	96ba                	add	a3,a3,a4
    80006364:	4609                	li	a2,2
    80006366:	00c69623          	sh	a2,12(a3)
    8000636a:	b5c9                	j	8000622c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000636c:	f9042583          	lw	a1,-112(s0)
    80006370:	20058793          	addi	a5,a1,512
    80006374:	0792                	slli	a5,a5,0x4
    80006376:	0001d517          	auipc	a0,0x1d
    8000637a:	d3250513          	addi	a0,a0,-718 # 800230a8 <disk+0xa8>
    8000637e:	953e                	add	a0,a0,a5
  if(write)
    80006380:	e20d11e3          	bnez	s10,800061a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006384:	20058713          	addi	a4,a1,512
    80006388:	00471693          	slli	a3,a4,0x4
    8000638c:	0001d717          	auipc	a4,0x1d
    80006390:	c7470713          	addi	a4,a4,-908 # 80023000 <disk>
    80006394:	9736                	add	a4,a4,a3
    80006396:	0a072423          	sw	zero,168(a4)
    8000639a:	b505                	j	800061ba <virtio_disk_rw+0xf4>

000000008000639c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	e04a                	sd	s2,0(sp)
    800063a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a8:	0001f517          	auipc	a0,0x1f
    800063ac:	d8050513          	addi	a0,a0,-640 # 80025128 <disk+0x2128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063b8:	10001737          	lui	a4,0x10001
    800063bc:	533c                	lw	a5,96(a4)
    800063be:	8b8d                	andi	a5,a5,3
    800063c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063c6:	0001f797          	auipc	a5,0x1f
    800063ca:	c3a78793          	addi	a5,a5,-966 # 80025000 <disk+0x2000>
    800063ce:	6b94                	ld	a3,16(a5)
    800063d0:	0207d703          	lhu	a4,32(a5)
    800063d4:	0026d783          	lhu	a5,2(a3)
    800063d8:	06f70163          	beq	a4,a5,8000643a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063dc:	0001d917          	auipc	s2,0x1d
    800063e0:	c2490913          	addi	s2,s2,-988 # 80023000 <disk>
    800063e4:	0001f497          	auipc	s1,0x1f
    800063e8:	c1c48493          	addi	s1,s1,-996 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063f0:	6898                	ld	a4,16(s1)
    800063f2:	0204d783          	lhu	a5,32(s1)
    800063f6:	8b9d                	andi	a5,a5,7
    800063f8:	078e                	slli	a5,a5,0x3
    800063fa:	97ba                	add	a5,a5,a4
    800063fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063fe:	20078713          	addi	a4,a5,512
    80006402:	0712                	slli	a4,a4,0x4
    80006404:	974a                	add	a4,a4,s2
    80006406:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000640a:	e731                	bnez	a4,80006456 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000640c:	20078793          	addi	a5,a5,512
    80006410:	0792                	slli	a5,a5,0x4
    80006412:	97ca                	add	a5,a5,s2
    80006414:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006416:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000641a:	ffffc097          	auipc	ra,0xffffc
    8000641e:	092080e7          	jalr	146(ra) # 800024ac <wakeup>

    disk.used_idx += 1;
    80006422:	0204d783          	lhu	a5,32(s1)
    80006426:	2785                	addiw	a5,a5,1
    80006428:	17c2                	slli	a5,a5,0x30
    8000642a:	93c1                	srli	a5,a5,0x30
    8000642c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006430:	6898                	ld	a4,16(s1)
    80006432:	00275703          	lhu	a4,2(a4)
    80006436:	faf71be3          	bne	a4,a5,800063ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000643a:	0001f517          	auipc	a0,0x1f
    8000643e:	cee50513          	addi	a0,a0,-786 # 80025128 <disk+0x2128>
    80006442:	ffffb097          	auipc	ra,0xffffb
    80006446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
}
    8000644a:	60e2                	ld	ra,24(sp)
    8000644c:	6442                	ld	s0,16(sp)
    8000644e:	64a2                	ld	s1,8(sp)
    80006450:	6902                	ld	s2,0(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret
      panic("virtio_disk_intr status");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	3b250513          	addi	a0,a0,946 # 80008808 <syscalls+0x3c0>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
