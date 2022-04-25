
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	92013103          	ld	sp,-1760(sp) # 80008920 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	eac78793          	addi	a5,a5,-340 # 80005f10 <timervec>
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
    80000130:	f18080e7          	jalr	-232(ra) # 80002044 <either_copyin>
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
    800001d8:	230080e7          	jalr	560(ra) # 80002404 <sleep>
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
    80000214:	dde080e7          	jalr	-546(ra) # 80001fee <either_copyout>
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
    800002f6:	da8080e7          	jalr	-600(ra) # 8000209a <procdump>
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
    8000044a:	156080e7          	jalr	342(ra) # 8000259c <wakeup>
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
    8000047c:	8d878793          	addi	a5,a5,-1832 # 80021d50 <devsw>
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
    800008a4:	cfc080e7          	jalr	-772(ra) # 8000259c <wakeup>
    
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
    80000930:	ad8080e7          	jalr	-1320(ra) # 80002404 <sleep>
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
    80000ed8:	ac0080e7          	jalr	-1344(ra) # 80002994 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	074080e7          	jalr	116(ra) # 80005f50 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	350080e7          	jalr	848(ra) # 80002234 <scheduler>
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
    80000f50:	a20080e7          	jalr	-1504(ra) # 8000296c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a40080e7          	jalr	-1472(ra) # 80002994 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	fde080e7          	jalr	-34(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fec080e7          	jalr	-20(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	1cc080e7          	jalr	460(ra) # 80003138 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	85c080e7          	jalr	-1956(ra) # 800037d0 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	806080e7          	jalr	-2042(ra) # 80004782 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	0ee080e7          	jalr	238(ra) # 80006072 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d2a080e7          	jalr	-726(ra) # 80001cb6 <userinit>
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
uint64 cont_timestamp = 0;	//when ticks > cont_timestamp contiue
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
    80001858:	eb448493          	addi	s1,s1,-332 # 80011708 <proc>
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
    80001872:	29aa0a13          	addi	s4,s4,666 # 80017b08 <tickslock>
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
    8000191c:	df048493          	addi	s1,s1,-528 # 80011708 <proc>
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
    8000193e:	1ce98993          	addi	s3,s3,462 # 80017b08 <tickslock>
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
    80001a14:	ec07a783          	lw	a5,-320(a5) # 800088d0 <first.1702>
    80001a18:	eb89                	bnez	a5,80001a2a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1a:	00001097          	auipc	ra,0x1
    80001a1e:	f92080e7          	jalr	-110(ra) # 800029ac <usertrapret>
}
    80001a22:	60a2                	ld	ra,8(sp)
    80001a24:	6402                	ld	s0,0(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret
    first = 0;
    80001a2a:	00007797          	auipc	a5,0x7
    80001a2e:	ea07a323          	sw	zero,-346(a5) # 800088d0 <first.1702>
    fsinit(ROOTDEV);
    80001a32:	4505                	li	a0,1
    80001a34:	00002097          	auipc	ra,0x2
    80001a38:	d1c080e7          	jalr	-740(ra) # 80003750 <fsinit>
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
    80001a60:	e7c78793          	addi	a5,a5,-388 # 800088d8 <nextpid>
    80001a64:	4384                	lw	s1,0(a5)
  nextpid++;
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
    80001be6:	b2648493          	addi	s1,s1,-1242 # 80011708 <proc>
    80001bea:	00016917          	auipc	s2,0x16
    80001bee:	f1e90913          	addi	s2,s2,-226 # 80017b08 <tickslock>
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
    80001c14:	a095                	j	80001c78 <allocproc+0xa2>
  p->last_runnable_time = ticks; 	//save time created for fcfs thingy, tickslock?
    80001c16:	00007797          	auipc	a5,0x7
    80001c1a:	4427e783          	lwu	a5,1090(a5) # 80009058 <ticks>
    80001c1e:	fc9c                	sd	a5,56(s1)
  p->mean_ticks = 0;
    80001c20:	0404b023          	sd	zero,64(s1)
  p->last_ticks = 0;
    80001c24:	0404b423          	sd	zero,72(s1)
  p->pid = allocpid();
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e16080e7          	jalr	-490(ra) # 80001a3e <allocpid>
    80001c30:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c32:	4785                	li	a5,1
    80001c34:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	ebe080e7          	jalr	-322(ra) # 80000af4 <kalloc>
    80001c3e:	892a                	mv	s2,a0
    80001c40:	e0c8                	sd	a0,128(s1)
    80001c42:	c131                	beqz	a0,80001c86 <allocproc+0xb0>
  p->pagetable = proc_pagetable(p);
    80001c44:	8526                	mv	a0,s1
    80001c46:	00000097          	auipc	ra,0x0
    80001c4a:	e3e080e7          	jalr	-450(ra) # 80001a84 <proc_pagetable>
    80001c4e:	892a                	mv	s2,a0
    80001c50:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80001c52:	c531                	beqz	a0,80001c9e <allocproc+0xc8>
  memset(&p->context, 0, sizeof(p->context));
    80001c54:	07000613          	li	a2,112
    80001c58:	4581                	li	a1,0
    80001c5a:	08848513          	addi	a0,s1,136
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	082080e7          	jalr	130(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c66:	00000797          	auipc	a5,0x0
    80001c6a:	d9278793          	addi	a5,a5,-622 # 800019f8 <forkret>
    80001c6e:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c70:	74bc                	ld	a5,104(s1)
    80001c72:	6705                	lui	a4,0x1
    80001c74:	97ba                	add	a5,a5,a4
    80001c76:	e8dc                	sd	a5,144(s1)
}
    80001c78:	8526                	mv	a0,s1
    80001c7a:	60e2                	ld	ra,24(sp)
    80001c7c:	6442                	ld	s0,16(sp)
    80001c7e:	64a2                	ld	s1,8(sp)
    80001c80:	6902                	ld	s2,0(sp)
    80001c82:	6105                	addi	sp,sp,32
    80001c84:	8082                	ret
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	eea080e7          	jalr	-278(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	bff1                	j	80001c78 <allocproc+0xa2>
    freeproc(p);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	ed2080e7          	jalr	-302(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	fee080e7          	jalr	-18(ra) # 80000c98 <release>
    return 0;
    80001cb2:	84ca                	mv	s1,s2
    80001cb4:	b7d1                	j	80001c78 <allocproc+0xa2>

0000000080001cb6 <userinit>:
{
    80001cb6:	1101                	addi	sp,sp,-32
    80001cb8:	ec06                	sd	ra,24(sp)
    80001cba:	e822                	sd	s0,16(sp)
    80001cbc:	e426                	sd	s1,8(sp)
    80001cbe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	f16080e7          	jalr	-234(ra) # 80001bd6 <allocproc>
    80001cc8:	84aa                	mv	s1,a0
  initproc = p;
    80001cca:	00007797          	auipc	a5,0x7
    80001cce:	38a7b323          	sd	a0,902(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd2:	03400613          	li	a2,52
    80001cd6:	00007597          	auipc	a1,0x7
    80001cda:	c0a58593          	addi	a1,a1,-1014 # 800088e0 <initcode>
    80001cde:	7d28                	ld	a0,120(a0)
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	688080e7          	jalr	1672(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001ce8:	6785                	lui	a5,0x1
    80001cea:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cec:	60d8                	ld	a4,128(s1)
    80001cee:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf2:	60d8                	ld	a4,128(s1)
    80001cf4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf6:	4641                	li	a2,16
    80001cf8:	00006597          	auipc	a1,0x6
    80001cfc:	50858593          	addi	a1,a1,1288 # 80008200 <digits+0x1c0>
    80001d00:	18048513          	addi	a0,s1,384
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	12e080e7          	jalr	302(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d0c:	00006517          	auipc	a0,0x6
    80001d10:	50450513          	addi	a0,a0,1284 # 80008210 <digits+0x1d0>
    80001d14:	00002097          	auipc	ra,0x2
    80001d18:	46a080e7          	jalr	1130(ra) # 8000417e <namei>
    80001d1c:	16a4bc23          	sd	a0,376(s1)
  p->time_state_changed = ticks;
    80001d20:	00007797          	auipc	a5,0x7
    80001d24:	3387a783          	lw	a5,824(a5) # 80009058 <ticks>
    80001d28:	ccfc                	sw	a5,92(s1)
  p->state = RUNNABLE;
    80001d2a:	470d                	li	a4,3
    80001d2c:	cc98                	sw	a4,24(s1)
  p->last_runnable_time = ticks;		//fcfs thingy
    80001d2e:	1782                	slli	a5,a5,0x20
    80001d30:	9381                	srli	a5,a5,0x20
    80001d32:	fc9c                	sd	a5,56(s1)
  release(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	f62080e7          	jalr	-158(ra) # 80000c98 <release>
}
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret

0000000080001d48 <growproc>:
{
    80001d48:	1101                	addi	sp,sp,-32
    80001d4a:	ec06                	sd	ra,24(sp)
    80001d4c:	e822                	sd	s0,16(sp)
    80001d4e:	e426                	sd	s1,8(sp)
    80001d50:	e04a                	sd	s2,0(sp)
    80001d52:	1000                	addi	s0,sp,32
    80001d54:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	c6a080e7          	jalr	-918(ra) # 800019c0 <myproc>
    80001d5e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d60:	792c                	ld	a1,112(a0)
    80001d62:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d66:	00904f63          	bgtz	s1,80001d84 <growproc+0x3c>
  } else if(n < 0){
    80001d6a:	0204cc63          	bltz	s1,80001da2 <growproc+0x5a>
  p->sz = sz;
    80001d6e:	1602                	slli	a2,a2,0x20
    80001d70:	9201                	srli	a2,a2,0x20
    80001d72:	06c93823          	sd	a2,112(s2)
  return 0;
    80001d76:	4501                	li	a0,0
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6902                	ld	s2,0(sp)
    80001d80:	6105                	addi	sp,sp,32
    80001d82:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d84:	9e25                	addw	a2,a2,s1
    80001d86:	1602                	slli	a2,a2,0x20
    80001d88:	9201                	srli	a2,a2,0x20
    80001d8a:	1582                	slli	a1,a1,0x20
    80001d8c:	9181                	srli	a1,a1,0x20
    80001d8e:	7d28                	ld	a0,120(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	692080e7          	jalr	1682(ra) # 80001422 <uvmalloc>
    80001d98:	0005061b          	sext.w	a2,a0
    80001d9c:	fa69                	bnez	a2,80001d6e <growproc+0x26>
      return -1;
    80001d9e:	557d                	li	a0,-1
    80001da0:	bfe1                	j	80001d78 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da2:	9e25                	addw	a2,a2,s1
    80001da4:	1602                	slli	a2,a2,0x20
    80001da6:	9201                	srli	a2,a2,0x20
    80001da8:	1582                	slli	a1,a1,0x20
    80001daa:	9181                	srli	a1,a1,0x20
    80001dac:	7d28                	ld	a0,120(a0)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	62c080e7          	jalr	1580(ra) # 800013da <uvmdealloc>
    80001db6:	0005061b          	sext.w	a2,a0
    80001dba:	bf55                	j	80001d6e <growproc+0x26>

0000000080001dbc <fork>:
{
    80001dbc:	7179                	addi	sp,sp,-48
    80001dbe:	f406                	sd	ra,40(sp)
    80001dc0:	f022                	sd	s0,32(sp)
    80001dc2:	ec26                	sd	s1,24(sp)
    80001dc4:	e84a                	sd	s2,16(sp)
    80001dc6:	e44e                	sd	s3,8(sp)
    80001dc8:	e052                	sd	s4,0(sp)
    80001dca:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	bf4080e7          	jalr	-1036(ra) # 800019c0 <myproc>
    80001dd4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	e00080e7          	jalr	-512(ra) # 80001bd6 <allocproc>
    80001dde:	12050b63          	beqz	a0,80001f14 <fork+0x158>
    80001de2:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de4:	0709b603          	ld	a2,112(s3)
    80001de8:	7d2c                	ld	a1,120(a0)
    80001dea:	0789b503          	ld	a0,120(s3)
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	780080e7          	jalr	1920(ra) # 8000156e <uvmcopy>
    80001df6:	04054663          	bltz	a0,80001e42 <fork+0x86>
  np->sz = p->sz;
    80001dfa:	0709b783          	ld	a5,112(s3)
    80001dfe:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80001e02:	0809b683          	ld	a3,128(s3)
    80001e06:	87b6                	mv	a5,a3
    80001e08:	08093703          	ld	a4,128(s2)
    80001e0c:	12068693          	addi	a3,a3,288
    80001e10:	0007b803          	ld	a6,0(a5)
    80001e14:	6788                	ld	a0,8(a5)
    80001e16:	6b8c                	ld	a1,16(a5)
    80001e18:	6f90                	ld	a2,24(a5)
    80001e1a:	01073023          	sd	a6,0(a4)
    80001e1e:	e708                	sd	a0,8(a4)
    80001e20:	eb0c                	sd	a1,16(a4)
    80001e22:	ef10                	sd	a2,24(a4)
    80001e24:	02078793          	addi	a5,a5,32
    80001e28:	02070713          	addi	a4,a4,32
    80001e2c:	fed792e3          	bne	a5,a3,80001e10 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e30:	08093783          	ld	a5,128(s2)
    80001e34:	0607b823          	sd	zero,112(a5)
    80001e38:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80001e3c:	17800a13          	li	s4,376
    80001e40:	a03d                	j	80001e6e <fork+0xb2>
    freeproc(np);
    80001e42:	854a                	mv	a0,s2
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	d2e080e7          	jalr	-722(ra) # 80001b72 <freeproc>
    release(&np->lock);
    80001e4c:	854a                	mv	a0,s2
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e4a080e7          	jalr	-438(ra) # 80000c98 <release>
    return -1;
    80001e56:	5a7d                	li	s4,-1
    80001e58:	a06d                	j	80001f02 <fork+0x146>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5a:	00003097          	auipc	ra,0x3
    80001e5e:	9ba080e7          	jalr	-1606(ra) # 80004814 <filedup>
    80001e62:	009907b3          	add	a5,s2,s1
    80001e66:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e68:	04a1                	addi	s1,s1,8
    80001e6a:	01448763          	beq	s1,s4,80001e78 <fork+0xbc>
    if(p->ofile[i])
    80001e6e:	009987b3          	add	a5,s3,s1
    80001e72:	6388                	ld	a0,0(a5)
    80001e74:	f17d                	bnez	a0,80001e5a <fork+0x9e>
    80001e76:	bfcd                	j	80001e68 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e78:	1789b503          	ld	a0,376(s3)
    80001e7c:	00002097          	auipc	ra,0x2
    80001e80:	b0e080e7          	jalr	-1266(ra) # 8000398a <idup>
    80001e84:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e88:	4641                	li	a2,16
    80001e8a:	18098593          	addi	a1,s3,384
    80001e8e:	18090513          	addi	a0,s2,384
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	fa0080e7          	jalr	-96(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e9a:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	df8080e7          	jalr	-520(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ea8:	0000f497          	auipc	s1,0xf
    80001eac:	43048493          	addi	s1,s1,1072 # 800112d8 <wait_lock>
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d32080e7          	jalr	-718(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eba:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dd8080e7          	jalr	-552(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ec8:	854a                	mv	a0,s2
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	d1a080e7          	jalr	-742(ra) # 80000be4 <acquire>
  np->running_time = 0;
    80001ed2:	04092c23          	sw	zero,88(s2)
  np->sleeping_time = 0;
    80001ed6:	04092823          	sw	zero,80(s2)
  np->runnable_time = 0;
    80001eda:	04092a23          	sw	zero,84(s2)
  np->time_state_changed = ticks;
    80001ede:	00007797          	auipc	a5,0x7
    80001ee2:	17a7a783          	lw	a5,378(a5) # 80009058 <ticks>
    80001ee6:	04f92e23          	sw	a5,92(s2)
  np->state = RUNNABLE;
    80001eea:	470d                	li	a4,3
    80001eec:	00e92c23          	sw	a4,24(s2)
  np->last_runnable_time = ticks;
    80001ef0:	1782                	slli	a5,a5,0x20
    80001ef2:	9381                	srli	a5,a5,0x20
    80001ef4:	02f93c23          	sd	a5,56(s2)
  release(&np->lock);
    80001ef8:	854a                	mv	a0,s2
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	d9e080e7          	jalr	-610(ra) # 80000c98 <release>
}
    80001f02:	8552                	mv	a0,s4
    80001f04:	70a2                	ld	ra,40(sp)
    80001f06:	7402                	ld	s0,32(sp)
    80001f08:	64e2                	ld	s1,24(sp)
    80001f0a:	6942                	ld	s2,16(sp)
    80001f0c:	69a2                	ld	s3,8(sp)
    80001f0e:	6a02                	ld	s4,0(sp)
    80001f10:	6145                	addi	sp,sp,48
    80001f12:	8082                	ret
    return -1;
    80001f14:	5a7d                	li	s4,-1
    80001f16:	b7f5                	j	80001f02 <fork+0x146>

0000000080001f18 <sched>:
{
    80001f18:	7179                	addi	sp,sp,-48
    80001f1a:	f406                	sd	ra,40(sp)
    80001f1c:	f022                	sd	s0,32(sp)
    80001f1e:	ec26                	sd	s1,24(sp)
    80001f20:	e84a                	sd	s2,16(sp)
    80001f22:	e44e                	sd	s3,8(sp)
    80001f24:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	a9a080e7          	jalr	-1382(ra) # 800019c0 <myproc>
    80001f2e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	c3a080e7          	jalr	-966(ra) # 80000b6a <holding>
    80001f38:	c93d                	beqz	a0,80001fae <sched+0x96>
    80001f3a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f3c:	2781                	sext.w	a5,a5
    80001f3e:	079e                	slli	a5,a5,0x7
    80001f40:	0000f717          	auipc	a4,0xf
    80001f44:	38070713          	addi	a4,a4,896 # 800112c0 <pid_lock>
    80001f48:	97ba                	add	a5,a5,a4
    80001f4a:	0a87a703          	lw	a4,168(a5)
    80001f4e:	4785                	li	a5,1
    80001f50:	06f71763          	bne	a4,a5,80001fbe <sched+0xa6>
  if(p->state == RUNNING)
    80001f54:	4c98                	lw	a4,24(s1)
    80001f56:	4791                	li	a5,4
    80001f58:	06f70b63          	beq	a4,a5,80001fce <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f5c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f60:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f62:	efb5                	bnez	a5,80001fde <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f66:	0000f917          	auipc	s2,0xf
    80001f6a:	35a90913          	addi	s2,s2,858 # 800112c0 <pid_lock>
    80001f6e:	2781                	sext.w	a5,a5
    80001f70:	079e                	slli	a5,a5,0x7
    80001f72:	97ca                	add	a5,a5,s2
    80001f74:	0ac7a983          	lw	s3,172(a5)
    80001f78:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f7a:	2781                	sext.w	a5,a5
    80001f7c:	079e                	slli	a5,a5,0x7
    80001f7e:	0000f597          	auipc	a1,0xf
    80001f82:	37a58593          	addi	a1,a1,890 # 800112f8 <cpus+0x8>
    80001f86:	95be                	add	a1,a1,a5
    80001f88:	08848513          	addi	a0,s1,136
    80001f8c:	00001097          	auipc	ra,0x1
    80001f90:	976080e7          	jalr	-1674(ra) # 80002902 <swtch>
    80001f94:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	97ca                	add	a5,a5,s2
    80001f9c:	0b37a623          	sw	s3,172(a5)
}
    80001fa0:	70a2                	ld	ra,40(sp)
    80001fa2:	7402                	ld	s0,32(sp)
    80001fa4:	64e2                	ld	s1,24(sp)
    80001fa6:	6942                	ld	s2,16(sp)
    80001fa8:	69a2                	ld	s3,8(sp)
    80001faa:	6145                	addi	sp,sp,48
    80001fac:	8082                	ret
    panic("sched p->lock");
    80001fae:	00006517          	auipc	a0,0x6
    80001fb2:	26a50513          	addi	a0,a0,618 # 80008218 <digits+0x1d8>
    80001fb6:	ffffe097          	auipc	ra,0xffffe
    80001fba:	588080e7          	jalr	1416(ra) # 8000053e <panic>
    panic("sched locks");
    80001fbe:	00006517          	auipc	a0,0x6
    80001fc2:	26a50513          	addi	a0,a0,618 # 80008228 <digits+0x1e8>
    80001fc6:	ffffe097          	auipc	ra,0xffffe
    80001fca:	578080e7          	jalr	1400(ra) # 8000053e <panic>
    panic("sched running");
    80001fce:	00006517          	auipc	a0,0x6
    80001fd2:	26a50513          	addi	a0,a0,618 # 80008238 <digits+0x1f8>
    80001fd6:	ffffe097          	auipc	ra,0xffffe
    80001fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001fde:	00006517          	auipc	a0,0x6
    80001fe2:	26a50513          	addi	a0,a0,618 # 80008248 <digits+0x208>
    80001fe6:	ffffe097          	auipc	ra,0xffffe
    80001fea:	558080e7          	jalr	1368(ra) # 8000053e <panic>

0000000080001fee <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001fee:	7179                	addi	sp,sp,-48
    80001ff0:	f406                	sd	ra,40(sp)
    80001ff2:	f022                	sd	s0,32(sp)
    80001ff4:	ec26                	sd	s1,24(sp)
    80001ff6:	e84a                	sd	s2,16(sp)
    80001ff8:	e44e                	sd	s3,8(sp)
    80001ffa:	e052                	sd	s4,0(sp)
    80001ffc:	1800                	addi	s0,sp,48
    80001ffe:	84aa                	mv	s1,a0
    80002000:	892e                	mv	s2,a1
    80002002:	89b2                	mv	s3,a2
    80002004:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	9ba080e7          	jalr	-1606(ra) # 800019c0 <myproc>
  if(user_dst){
    8000200e:	c08d                	beqz	s1,80002030 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002010:	86d2                	mv	a3,s4
    80002012:	864e                	mv	a2,s3
    80002014:	85ca                	mv	a1,s2
    80002016:	7d28                	ld	a0,120(a0)
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	65a080e7          	jalr	1626(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002020:	70a2                	ld	ra,40(sp)
    80002022:	7402                	ld	s0,32(sp)
    80002024:	64e2                	ld	s1,24(sp)
    80002026:	6942                	ld	s2,16(sp)
    80002028:	69a2                	ld	s3,8(sp)
    8000202a:	6a02                	ld	s4,0(sp)
    8000202c:	6145                	addi	sp,sp,48
    8000202e:	8082                	ret
    memmove((char *)dst, src, len);
    80002030:	000a061b          	sext.w	a2,s4
    80002034:	85ce                	mv	a1,s3
    80002036:	854a                	mv	a0,s2
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	d08080e7          	jalr	-760(ra) # 80000d40 <memmove>
    return 0;
    80002040:	8526                	mv	a0,s1
    80002042:	bff9                	j	80002020 <either_copyout+0x32>

0000000080002044 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	e052                	sd	s4,0(sp)
    80002052:	1800                	addi	s0,sp,48
    80002054:	892a                	mv	s2,a0
    80002056:	84ae                	mv	s1,a1
    80002058:	89b2                	mv	s3,a2
    8000205a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	964080e7          	jalr	-1692(ra) # 800019c0 <myproc>
  if(user_src){
    80002064:	c08d                	beqz	s1,80002086 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002066:	86d2                	mv	a3,s4
    80002068:	864e                	mv	a2,s3
    8000206a:	85ca                	mv	a1,s2
    8000206c:	7d28                	ld	a0,120(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	690080e7          	jalr	1680(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002076:	70a2                	ld	ra,40(sp)
    80002078:	7402                	ld	s0,32(sp)
    8000207a:	64e2                	ld	s1,24(sp)
    8000207c:	6942                	ld	s2,16(sp)
    8000207e:	69a2                	ld	s3,8(sp)
    80002080:	6a02                	ld	s4,0(sp)
    80002082:	6145                	addi	sp,sp,48
    80002084:	8082                	ret
    memmove(dst, (char*)src, len);
    80002086:	000a061b          	sext.w	a2,s4
    8000208a:	85ce                	mv	a1,s3
    8000208c:	854a                	mv	a0,s2
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	cb2080e7          	jalr	-846(ra) # 80000d40 <memmove>
    return 0;
    80002096:	8526                	mv	a0,s1
    80002098:	bff9                	j	80002076 <either_copyin+0x32>

000000008000209a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000209a:	715d                	addi	sp,sp,-80
    8000209c:	e486                	sd	ra,72(sp)
    8000209e:	e0a2                	sd	s0,64(sp)
    800020a0:	fc26                	sd	s1,56(sp)
    800020a2:	f84a                	sd	s2,48(sp)
    800020a4:	f44e                	sd	s3,40(sp)
    800020a6:	f052                	sd	s4,32(sp)
    800020a8:	ec56                	sd	s5,24(sp)
    800020aa:	e85a                	sd	s6,16(sp)
    800020ac:	e45e                	sd	s7,8(sp)
    800020ae:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	01850513          	addi	a0,a0,24 # 800080c8 <digits+0x88>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	4d0080e7          	jalr	1232(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800020c0:	0000f497          	auipc	s1,0xf
    800020c4:	7c848493          	addi	s1,s1,1992 # 80011888 <proc+0x180>
    800020c8:	00016917          	auipc	s2,0x16
    800020cc:	bc090913          	addi	s2,s2,-1088 # 80017c88 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800020d0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800020d2:	00006997          	auipc	s3,0x6
    800020d6:	18e98993          	addi	s3,s3,398 # 80008260 <digits+0x220>
    printf("%d %s %s", p->pid, state, p->name);
    800020da:	00006a97          	auipc	s5,0x6
    800020de:	18ea8a93          	addi	s5,s5,398 # 80008268 <digits+0x228>
    printf("\n");
    800020e2:	00006a17          	auipc	s4,0x6
    800020e6:	fe6a0a13          	addi	s4,s4,-26 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800020ea:	00006b97          	auipc	s7,0x6
    800020ee:	27eb8b93          	addi	s7,s7,638 # 80008368 <states.1739>
    800020f2:	a00d                	j	80002114 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800020f4:	eb06a583          	lw	a1,-336(a3)
    800020f8:	8556                	mv	a0,s5
    800020fa:	ffffe097          	auipc	ra,0xffffe
    800020fe:	48e080e7          	jalr	1166(ra) # 80000588 <printf>
    printf("\n");
    80002102:	8552                	mv	a0,s4
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	484080e7          	jalr	1156(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000210c:	19048493          	addi	s1,s1,400
    80002110:	03248163          	beq	s1,s2,80002132 <procdump+0x98>
    if(p->state == UNUSED)
    80002114:	86a6                	mv	a3,s1
    80002116:	e984a783          	lw	a5,-360(s1)
    8000211a:	dbed                	beqz	a5,8000210c <procdump+0x72>
      state = "???";
    8000211c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000211e:	fcfb6be3          	bltu	s6,a5,800020f4 <procdump+0x5a>
    80002122:	1782                	slli	a5,a5,0x20
    80002124:	9381                	srli	a5,a5,0x20
    80002126:	078e                	slli	a5,a5,0x3
    80002128:	97de                	add	a5,a5,s7
    8000212a:	6390                	ld	a2,0(a5)
    8000212c:	f661                	bnez	a2,800020f4 <procdump+0x5a>
      state = "???";
    8000212e:	864e                	mv	a2,s3
    80002130:	b7d1                	j	800020f4 <procdump+0x5a>
  }
}
    80002132:	60a6                	ld	ra,72(sp)
    80002134:	6406                	ld	s0,64(sp)
    80002136:	74e2                	ld	s1,56(sp)
    80002138:	7942                	ld	s2,48(sp)
    8000213a:	79a2                	ld	s3,40(sp)
    8000213c:	7a02                	ld	s4,32(sp)
    8000213e:	6ae2                	ld	s5,24(sp)
    80002140:	6b42                	ld	s6,16(sp)
    80002142:	6ba2                	ld	s7,8(sp)
    80002144:	6161                	addi	sp,sp,80
    80002146:	8082                	ret

0000000080002148 <print_stats>:
  }
	return kill(cur->pid);
}

int print_stats(void) //*
{
    80002148:	1101                	addi	sp,sp,-32
    8000214a:	ec06                	sd	ra,24(sp)
    8000214c:	e822                	sd	s0,16(sp)
    8000214e:	e426                	sd	s1,8(sp)
    80002150:	e04a                	sd	s2,0(sp)
    80002152:	1000                	addi	s0,sp,32
  acquire(&stats_lock);
    80002154:	0000f497          	auipc	s1,0xf
    80002158:	59c48493          	addi	s1,s1,1436 # 800116f0 <stats_lock>
    8000215c:	8526                	mv	a0,s1
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	a86080e7          	jalr	-1402(ra) # 80000be4 <acquire>
  printf("running process time mean - %d\n", runnable_processes_mean);
    80002166:	00007917          	auipc	s2,0x7
    8000216a:	ece90913          	addi	s2,s2,-306 # 80009034 <runnable_processes_mean>
    8000216e:	00092583          	lw	a1,0(s2)
    80002172:	00006517          	auipc	a0,0x6
    80002176:	10650513          	addi	a0,a0,262 # 80008278 <digits+0x238>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	40e080e7          	jalr	1038(ra) # 80000588 <printf>
  printf("runnable process time mean - %d\n", runnable_processes_mean);
    80002182:	00092583          	lw	a1,0(s2)
    80002186:	00006517          	auipc	a0,0x6
    8000218a:	11250513          	addi	a0,a0,274 # 80008298 <digits+0x258>
    8000218e:	ffffe097          	auipc	ra,0xffffe
    80002192:	3fa080e7          	jalr	1018(ra) # 80000588 <printf>
  printf("sleeping process time mean - %d\n", sleeping_processes_mean);
    80002196:	00007597          	auipc	a1,0x7
    8000219a:	e9a5a583          	lw	a1,-358(a1) # 80009030 <sleeping_processes_mean>
    8000219e:	00006517          	auipc	a0,0x6
    800021a2:	12250513          	addi	a0,a0,290 # 800082c0 <digits+0x280>
    800021a6:	ffffe097          	auipc	ra,0xffffe
    800021aa:	3e2080e7          	jalr	994(ra) # 80000588 <printf>
  printf("program running time - %d\n", program_time);
    800021ae:	00007597          	auipc	a1,0x7
    800021b2:	e965a583          	lw	a1,-362(a1) # 80009044 <program_time>
    800021b6:	00006517          	auipc	a0,0x6
    800021ba:	13250513          	addi	a0,a0,306 # 800082e8 <digits+0x2a8>
    800021be:	ffffe097          	auipc	ra,0xffffe
    800021c2:	3ca080e7          	jalr	970(ra) # 80000588 <printf>
  printf("cpu utiliztion - %d\n", cpu_utilization);
    800021c6:	00007597          	auipc	a1,0x7
    800021ca:	e7a5a583          	lw	a1,-390(a1) # 80009040 <cpu_utilization>
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	13a50513          	addi	a0,a0,314 # 80008308 <digits+0x2c8>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	3b2080e7          	jalr	946(ra) # 80000588 <printf>
  release(&stats_lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	ab8080e7          	jalr	-1352(ra) # 80000c98 <release>
  return 1;
}
    800021e8:	4505                	li	a0,1
    800021ea:	60e2                	ld	ra,24(sp)
    800021ec:	6442                	ld	s0,16(sp)
    800021ee:	64a2                	ld	s1,8(sp)
    800021f0:	6902                	ld	s2,0(sp)
    800021f2:	6105                	addi	sp,sp,32
    800021f4:	8082                	ret

00000000800021f6 <update_process_timing_in_state>:

void update_process_timing_in_state(struct proc *p, int state){
    800021f6:	1141                	addi	sp,sp,-16
    800021f8:	e422                	sd	s0,8(sp)
    800021fa:	0800                	addi	s0,sp,16
  int time_in_ticks = ticks - p->time_state_changed;
    800021fc:	00007717          	auipc	a4,0x7
    80002200:	e5c72703          	lw	a4,-420(a4) # 80009058 <ticks>
    80002204:	4d7c                	lw	a5,92(a0)
    80002206:	40f707bb          	subw	a5,a4,a5
  switch (state)
    8000220a:	468d                	li	a3,3
    8000220c:	00d58c63          	beq	a1,a3,80002224 <update_process_timing_in_state+0x2e>
    80002210:	4691                	li	a3,4
    80002212:	00d59d63          	bne	a1,a3,8000222c <update_process_timing_in_state+0x36>
  {
  case RUNNING:
    p->running_time += time_in_ticks;
    80002216:	4d34                	lw	a3,88(a0)
    80002218:	9fb5                	addw	a5,a5,a3
    8000221a:	cd3c                	sw	a5,88(a0)
    break;
  default:
    p->sleeping_time += time_in_ticks;
    break;
  }
  p->time_state_changed = ticks;
    8000221c:	cd78                	sw	a4,92(a0)
}
    8000221e:	6422                	ld	s0,8(sp)
    80002220:	0141                	addi	sp,sp,16
    80002222:	8082                	ret
    p->runnable_time += time_in_ticks;
    80002224:	4974                	lw	a3,84(a0)
    80002226:	9fb5                	addw	a5,a5,a3
    80002228:	c97c                	sw	a5,84(a0)
    break;
    8000222a:	bfcd                	j	8000221c <update_process_timing_in_state+0x26>
    p->sleeping_time += time_in_ticks;
    8000222c:	4934                	lw	a3,80(a0)
    8000222e:	9fb5                	addw	a5,a5,a3
    80002230:	c93c                	sw	a5,80(a0)
    break;
    80002232:	b7ed                	j	8000221c <update_process_timing_in_state+0x26>

0000000080002234 <scheduler>:
{
    80002234:	711d                	addi	sp,sp,-96
    80002236:	ec86                	sd	ra,88(sp)
    80002238:	e8a2                	sd	s0,80(sp)
    8000223a:	e4a6                	sd	s1,72(sp)
    8000223c:	e0ca                	sd	s2,64(sp)
    8000223e:	fc4e                	sd	s3,56(sp)
    80002240:	f852                	sd	s4,48(sp)
    80002242:	f456                	sd	s5,40(sp)
    80002244:	f05a                	sd	s6,32(sp)
    80002246:	ec5e                	sd	s7,24(sp)
    80002248:	e862                	sd	s8,16(sp)
    8000224a:	e466                	sd	s9,8(sp)
    8000224c:	e06a                	sd	s10,0(sp)
    8000224e:	1080                	addi	s0,sp,96
    80002250:	8792                	mv	a5,tp
  int id = r_tp();
    80002252:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002254:	00779c13          	slli	s8,a5,0x7
    80002258:	0000f717          	auipc	a4,0xf
    8000225c:	06870713          	addi	a4,a4,104 # 800112c0 <pid_lock>
    80002260:	9762                	add	a4,a4,s8
    80002262:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &min_time_proc->context);
    80002266:	0000f717          	auipc	a4,0xf
    8000226a:	09270713          	addi	a4,a4,146 # 800112f8 <cpus+0x8>
    8000226e:	9c3a                	add	s8,s8,a4
    struct proc *min_time_proc = proc;
    80002270:	0000fa17          	auipc	s4,0xf
    80002274:	498a0a13          	addi	s4,s4,1176 # 80011708 <proc>
    for(p = proc; p < &proc[NPROC]; p++) { //maybe
    80002278:	00016497          	auipc	s1,0x16
    8000227c:	89048493          	addi	s1,s1,-1904 # 80017b08 <tickslock>
    if((min_time_proc->state == RUNNABLE) & (ticks > cont_timestamp || p->pid == INIT_PROC_PID || p->pid == SHELL_PROC_PID)) {
    80002280:	00007997          	auipc	s3,0x7
    80002284:	dd898993          	addi	s3,s3,-552 # 80009058 <ticks>
    80002288:	00007b97          	auipc	s7,0x7
    8000228c:	da0b8b93          	addi	s7,s7,-608 # 80009028 <cont_timestamp>
      update_process_timing_in_state(p, p->state);
    80002290:	00015b17          	auipc	s6,0x15
    80002294:	478b0b13          	addi	s6,s6,1144 # 80017708 <proc+0x6000>
      c->proc = min_time_proc;
    80002298:	079e                	slli	a5,a5,0x7
    8000229a:	0000fa97          	auipc	s5,0xf
    8000229e:	026a8a93          	addi	s5,s5,38 # 800112c0 <pid_lock>
    800022a2:	9abe                	add	s5,s5,a5
    800022a4:	a865                	j	8000235c <scheduler+0x128>
    for(p = proc; p < &proc[NPROC]; p++) { //maybe
    800022a6:	19078793          	addi	a5,a5,400
    800022aa:	00978c63          	beq	a5,s1,800022c2 <scheduler+0x8e>
      if( (p->state == RUNNABLE) && ( p->mean_ticks <= min_time_proc->mean_ticks) ) 
    800022ae:	4f98                	lw	a4,24(a5)
    800022b0:	fed71be3          	bne	a4,a3,800022a6 <scheduler+0x72>
    800022b4:	63b0                	ld	a2,64(a5)
    800022b6:	04093703          	ld	a4,64(s2)
    800022ba:	fec766e3          	bltu	a4,a2,800022a6 <scheduler+0x72>
    800022be:	893e                	mv	s2,a5
    800022c0:	b7dd                	j	800022a6 <scheduler+0x72>
    acquire(&min_time_proc->lock);
    800022c2:	8cca                	mv	s9,s2
    800022c4:	854a                	mv	a0,s2
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	91e080e7          	jalr	-1762(ra) # 80000be4 <acquire>
    if((min_time_proc->state == RUNNABLE) & (ticks > cont_timestamp || p->pid == INIT_PROC_PID || p->pid == SHELL_PROC_PID)) {
    800022ce:	01892683          	lw	a3,24(s2)
    800022d2:	0009e703          	lwu	a4,0(s3)
    800022d6:	000bb783          	ld	a5,0(s7)
    800022da:	00e7e863          	bltu	a5,a4,800022ea <scheduler+0xb6>
    800022de:	430b2783          	lw	a5,1072(s6)
    800022e2:	37fd                	addiw	a5,a5,-1
    800022e4:	4705                	li	a4,1
    800022e6:	06f76663          	bltu	a4,a5,80002352 <scheduler+0x11e>
    800022ea:	478d                	li	a5,3
    800022ec:	06f69363          	bne	a3,a5,80002352 <scheduler+0x11e>
      update_process_timing_in_state(p, p->state);
    800022f0:	418b2583          	lw	a1,1048(s6)
    800022f4:	8526                	mv	a0,s1
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	f00080e7          	jalr	-256(ra) # 800021f6 <update_process_timing_in_state>
      min_time_proc->state = RUNNING;
    800022fe:	4791                	li	a5,4
    80002300:	00f92c23          	sw	a5,24(s2)
      c->proc = min_time_proc;
    80002304:	032ab823          	sd	s2,48(s5)
      uint start_ticks = ticks;
    80002308:	0009ad03          	lw	s10,0(s3)
      swtch(&c->context, &min_time_proc->context);
    8000230c:	08890593          	addi	a1,s2,136
    80002310:	8562                	mv	a0,s8
    80002312:	00000097          	auipc	ra,0x0
    80002316:	5f0080e7          	jalr	1520(ra) # 80002902 <swtch>
      min_time_proc->last_ticks = ticks - start_ticks;
    8000231a:	0009a703          	lw	a4,0(s3)
    8000231e:	41a7073b          	subw	a4,a4,s10
    80002322:	1702                	slli	a4,a4,0x20
    80002324:	9301                	srli	a4,a4,0x20
    80002326:	04e93423          	sd	a4,72(s2)
      min_time_proc->mean_ticks = ( (10-rate) * min_time_proc->mean_ticks + min_time_proc->last_ticks * rate) / 10;
    8000232a:	00006697          	auipc	a3,0x6
    8000232e:	5aa6a683          	lw	a3,1450(a3) # 800088d4 <rate>
    80002332:	47a9                	li	a5,10
    80002334:	9f95                	subw	a5,a5,a3
    80002336:	04093603          	ld	a2,64(s2)
    8000233a:	02c787b3          	mul	a5,a5,a2
    8000233e:	02e68733          	mul	a4,a3,a4
    80002342:	97ba                	add	a5,a5,a4
    80002344:	4729                	li	a4,10
    80002346:	02e7d7b3          	divu	a5,a5,a4
    8000234a:	04f93023          	sd	a5,64(s2)
      c->proc = 0;
    8000234e:	020ab823          	sd	zero,48(s5)
    release(&min_time_proc->lock); 
    80002352:	8566                	mv	a0,s9
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	944080e7          	jalr	-1724(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000235c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002360:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002364:	10079073          	csrw	sstatus,a5
    struct proc *min_time_proc = proc;
    80002368:	8952                	mv	s2,s4
    for(p = proc; p < &proc[NPROC]; p++) { //maybe
    8000236a:	87d2                	mv	a5,s4
      if( (p->state == RUNNABLE) && ( p->mean_ticks <= min_time_proc->mean_ticks) ) 
    8000236c:	468d                	li	a3,3
    8000236e:	b781                	j	800022ae <scheduler+0x7a>

0000000080002370 <yield>:
{
    80002370:	1101                	addi	sp,sp,-32
    80002372:	ec06                	sd	ra,24(sp)
    80002374:	e822                	sd	s0,16(sp)
    80002376:	e426                	sd	s1,8(sp)
    80002378:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	646080e7          	jalr	1606(ra) # 800019c0 <myproc>
    80002382:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	860080e7          	jalr	-1952(ra) # 80000be4 <acquire>
  update_process_timing_in_state(p, p->state);
    8000238c:	4c8c                	lw	a1,24(s1)
    8000238e:	8526                	mv	a0,s1
    80002390:	00000097          	auipc	ra,0x0
    80002394:	e66080e7          	jalr	-410(ra) # 800021f6 <update_process_timing_in_state>
  p->state = RUNNABLE;
    80002398:	478d                	li	a5,3
    8000239a:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000239c:	00007797          	auipc	a5,0x7
    800023a0:	cbc7e783          	lwu	a5,-836(a5) # 80009058 <ticks>
    800023a4:	fc9c                	sd	a5,56(s1)
  sched();
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	b72080e7          	jalr	-1166(ra) # 80001f18 <sched>
  release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8e8080e7          	jalr	-1816(ra) # 80000c98 <release>
}
    800023b8:	60e2                	ld	ra,24(sp)
    800023ba:	6442                	ld	s0,16(sp)
    800023bc:	64a2                	ld	s1,8(sp)
    800023be:	6105                	addi	sp,sp,32
    800023c0:	8082                	ret

00000000800023c2 <pause_system>:
	if(seconds<=0)
    800023c2:	02a05f63          	blez	a0,80002400 <pause_system+0x3e>
int pause_system(int seconds){
    800023c6:	1141                	addi	sp,sp,-16
    800023c8:	e406                	sd	ra,8(sp)
    800023ca:	e022                	sd	s0,0(sp)
    800023cc:	0800                	addi	s0,sp,16
	cont_timestamp = ticks + seconds * 10;
    800023ce:	0025179b          	slliw	a5,a0,0x2
    800023d2:	9fa9                	addw	a5,a5,a0
    800023d4:	0017979b          	slliw	a5,a5,0x1
    800023d8:	00007717          	auipc	a4,0x7
    800023dc:	c8072703          	lw	a4,-896(a4) # 80009058 <ticks>
    800023e0:	9fb9                	addw	a5,a5,a4
    800023e2:	1782                	slli	a5,a5,0x20
    800023e4:	9381                	srli	a5,a5,0x20
    800023e6:	00007717          	auipc	a4,0x7
    800023ea:	c4f73123          	sd	a5,-958(a4) # 80009028 <cont_timestamp>
	yield();
    800023ee:	00000097          	auipc	ra,0x0
    800023f2:	f82080e7          	jalr	-126(ra) # 80002370 <yield>
	return 1;
    800023f6:	4505                	li	a0,1
}
    800023f8:	60a2                	ld	ra,8(sp)
    800023fa:	6402                	ld	s0,0(sp)
    800023fc:	0141                	addi	sp,sp,16
    800023fe:	8082                	ret
		return 0;
    80002400:	4501                	li	a0,0
}
    80002402:	8082                	ret

0000000080002404 <sleep>:
{
    80002404:	7179                	addi	sp,sp,-48
    80002406:	f406                	sd	ra,40(sp)
    80002408:	f022                	sd	s0,32(sp)
    8000240a:	ec26                	sd	s1,24(sp)
    8000240c:	e84a                	sd	s2,16(sp)
    8000240e:	e44e                	sd	s3,8(sp)
    80002410:	1800                	addi	s0,sp,48
    80002412:	89aa                	mv	s3,a0
    80002414:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	5aa080e7          	jalr	1450(ra) # 800019c0 <myproc>
    8000241e:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
  release(lk);
    80002428:	854a                	mv	a0,s2
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	86e080e7          	jalr	-1938(ra) # 80000c98 <release>
  p->chan = chan;
    80002432:	0334b023          	sd	s3,32(s1)
  update_process_timing_in_state(p, p->state);
    80002436:	4c8c                	lw	a1,24(s1)
    80002438:	8526                	mv	a0,s1
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	dbc080e7          	jalr	-580(ra) # 800021f6 <update_process_timing_in_state>
  p->state = SLEEPING;
    80002442:	4789                	li	a5,2
    80002444:	cc9c                	sw	a5,24(s1)
  sched();
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	ad2080e7          	jalr	-1326(ra) # 80001f18 <sched>
  p->chan = 0;
    8000244e:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
  acquire(lk);
    8000245c:	854a                	mv	a0,s2
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	786080e7          	jalr	1926(ra) # 80000be4 <acquire>
}
    80002466:	70a2                	ld	ra,40(sp)
    80002468:	7402                	ld	s0,32(sp)
    8000246a:	64e2                	ld	s1,24(sp)
    8000246c:	6942                	ld	s2,16(sp)
    8000246e:	69a2                	ld	s3,8(sp)
    80002470:	6145                	addi	sp,sp,48
    80002472:	8082                	ret

0000000080002474 <wait>:
{
    80002474:	715d                	addi	sp,sp,-80
    80002476:	e486                	sd	ra,72(sp)
    80002478:	e0a2                	sd	s0,64(sp)
    8000247a:	fc26                	sd	s1,56(sp)
    8000247c:	f84a                	sd	s2,48(sp)
    8000247e:	f44e                	sd	s3,40(sp)
    80002480:	f052                	sd	s4,32(sp)
    80002482:	ec56                	sd	s5,24(sp)
    80002484:	e85a                	sd	s6,16(sp)
    80002486:	e45e                	sd	s7,8(sp)
    80002488:	e062                	sd	s8,0(sp)
    8000248a:	0880                	addi	s0,sp,80
    8000248c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	532080e7          	jalr	1330(ra) # 800019c0 <myproc>
    80002496:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002498:	0000f517          	auipc	a0,0xf
    8000249c:	e4050513          	addi	a0,a0,-448 # 800112d8 <wait_lock>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
    havekids = 0;
    800024a8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024aa:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800024ac:	00015997          	auipc	s3,0x15
    800024b0:	65c98993          	addi	s3,s3,1628 # 80017b08 <tickslock>
        havekids = 1;
    800024b4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024b6:	0000fc17          	auipc	s8,0xf
    800024ba:	e22c0c13          	addi	s8,s8,-478 # 800112d8 <wait_lock>
    havekids = 0;
    800024be:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024c0:	0000f497          	auipc	s1,0xf
    800024c4:	24848493          	addi	s1,s1,584 # 80011708 <proc>
    800024c8:	a0bd                	j	80002536 <wait+0xc2>
          pid = np->pid;
    800024ca:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024ce:	000b0e63          	beqz	s6,800024ea <wait+0x76>
    800024d2:	4691                	li	a3,4
    800024d4:	02c48613          	addi	a2,s1,44
    800024d8:	85da                	mv	a1,s6
    800024da:	07893503          	ld	a0,120(s2)
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	194080e7          	jalr	404(ra) # 80001672 <copyout>
    800024e6:	02054563          	bltz	a0,80002510 <wait+0x9c>
          freeproc(np);
    800024ea:	8526                	mv	a0,s1
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	686080e7          	jalr	1670(ra) # 80001b72 <freeproc>
          release(&np->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a2080e7          	jalr	1954(ra) # 80000c98 <release>
          release(&wait_lock);
    800024fe:	0000f517          	auipc	a0,0xf
    80002502:	dda50513          	addi	a0,a0,-550 # 800112d8 <wait_lock>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	792080e7          	jalr	1938(ra) # 80000c98 <release>
          return pid;
    8000250e:	a09d                	j	80002574 <wait+0x100>
            release(&np->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	786080e7          	jalr	1926(ra) # 80000c98 <release>
            release(&wait_lock);
    8000251a:	0000f517          	auipc	a0,0xf
    8000251e:	dbe50513          	addi	a0,a0,-578 # 800112d8 <wait_lock>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	776080e7          	jalr	1910(ra) # 80000c98 <release>
            return -1;
    8000252a:	59fd                	li	s3,-1
    8000252c:	a0a1                	j	80002574 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000252e:	19048493          	addi	s1,s1,400
    80002532:	03348463          	beq	s1,s3,8000255a <wait+0xe6>
      if(np->parent == p){
    80002536:	70bc                	ld	a5,96(s1)
    80002538:	ff279be3          	bne	a5,s2,8000252e <wait+0xba>
        acquire(&np->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	6a6080e7          	jalr	1702(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002546:	4c9c                	lw	a5,24(s1)
    80002548:	f94781e3          	beq	a5,s4,800024ca <wait+0x56>
        release(&np->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	74a080e7          	jalr	1866(ra) # 80000c98 <release>
        havekids = 1;
    80002556:	8756                	mv	a4,s5
    80002558:	bfd9                	j	8000252e <wait+0xba>
    if(!havekids || p->killed){
    8000255a:	c701                	beqz	a4,80002562 <wait+0xee>
    8000255c:	02892783          	lw	a5,40(s2)
    80002560:	c79d                	beqz	a5,8000258e <wait+0x11a>
      release(&wait_lock);
    80002562:	0000f517          	auipc	a0,0xf
    80002566:	d7650513          	addi	a0,a0,-650 # 800112d8 <wait_lock>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	72e080e7          	jalr	1838(ra) # 80000c98 <release>
      return -1;
    80002572:	59fd                	li	s3,-1
}
    80002574:	854e                	mv	a0,s3
    80002576:	60a6                	ld	ra,72(sp)
    80002578:	6406                	ld	s0,64(sp)
    8000257a:	74e2                	ld	s1,56(sp)
    8000257c:	7942                	ld	s2,48(sp)
    8000257e:	79a2                	ld	s3,40(sp)
    80002580:	7a02                	ld	s4,32(sp)
    80002582:	6ae2                	ld	s5,24(sp)
    80002584:	6b42                	ld	s6,16(sp)
    80002586:	6ba2                	ld	s7,8(sp)
    80002588:	6c02                	ld	s8,0(sp)
    8000258a:	6161                	addi	sp,sp,80
    8000258c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000258e:	85e2                	mv	a1,s8
    80002590:	854a                	mv	a0,s2
    80002592:	00000097          	auipc	ra,0x0
    80002596:	e72080e7          	jalr	-398(ra) # 80002404 <sleep>
    havekids = 0;
    8000259a:	b715                	j	800024be <wait+0x4a>

000000008000259c <wakeup>:
{
    8000259c:	7139                	addi	sp,sp,-64
    8000259e:	fc06                	sd	ra,56(sp)
    800025a0:	f822                	sd	s0,48(sp)
    800025a2:	f426                	sd	s1,40(sp)
    800025a4:	f04a                	sd	s2,32(sp)
    800025a6:	ec4e                	sd	s3,24(sp)
    800025a8:	e852                	sd	s4,16(sp)
    800025aa:	e456                	sd	s5,8(sp)
    800025ac:	e05a                	sd	s6,0(sp)
    800025ae:	0080                	addi	s0,sp,64
    800025b0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b2:	0000f497          	auipc	s1,0xf
    800025b6:	15648493          	addi	s1,s1,342 # 80011708 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    800025ba:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025bc:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    800025be:	00007a97          	auipc	s5,0x7
    800025c2:	a9aa8a93          	addi	s5,s5,-1382 # 80009058 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025c6:	00015917          	auipc	s2,0x15
    800025ca:	54290913          	addi	s2,s2,1346 # 80017b08 <tickslock>
    800025ce:	a811                	j	800025e2 <wakeup+0x46>
      release(&p->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6c6080e7          	jalr	1734(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025da:	19048493          	addi	s1,s1,400
    800025de:	03248f63          	beq	s1,s2,8000261c <wakeup+0x80>
    if(p != myproc()){
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	3de080e7          	jalr	990(ra) # 800019c0 <myproc>
    800025ea:	fea488e3          	beq	s1,a0,800025da <wakeup+0x3e>
      acquire(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	5f4080e7          	jalr	1524(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800025f8:	4c9c                	lw	a5,24(s1)
    800025fa:	fd379be3          	bne	a5,s3,800025d0 <wakeup+0x34>
    800025fe:	709c                	ld	a5,32(s1)
    80002600:	fd4798e3          	bne	a5,s4,800025d0 <wakeup+0x34>
        update_process_timing_in_state(p, p->state);
    80002604:	85ce                	mv	a1,s3
    80002606:	8526                	mv	a0,s1
    80002608:	00000097          	auipc	ra,0x0
    8000260c:	bee080e7          	jalr	-1042(ra) # 800021f6 <update_process_timing_in_state>
        p->state = RUNNABLE;
    80002610:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002614:	000ae783          	lwu	a5,0(s5)
    80002618:	fc9c                	sd	a5,56(s1)
    8000261a:	bf5d                	j	800025d0 <wakeup+0x34>
}
    8000261c:	70e2                	ld	ra,56(sp)
    8000261e:	7442                	ld	s0,48(sp)
    80002620:	74a2                	ld	s1,40(sp)
    80002622:	7902                	ld	s2,32(sp)
    80002624:	69e2                	ld	s3,24(sp)
    80002626:	6a42                	ld	s4,16(sp)
    80002628:	6aa2                	ld	s5,8(sp)
    8000262a:	6b02                	ld	s6,0(sp)
    8000262c:	6121                	addi	sp,sp,64
    8000262e:	8082                	ret

0000000080002630 <reparent>:
{
    80002630:	7179                	addi	sp,sp,-48
    80002632:	f406                	sd	ra,40(sp)
    80002634:	f022                	sd	s0,32(sp)
    80002636:	ec26                	sd	s1,24(sp)
    80002638:	e84a                	sd	s2,16(sp)
    8000263a:	e44e                	sd	s3,8(sp)
    8000263c:	e052                	sd	s4,0(sp)
    8000263e:	1800                	addi	s0,sp,48
    80002640:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002642:	0000f497          	auipc	s1,0xf
    80002646:	0c648493          	addi	s1,s1,198 # 80011708 <proc>
      pp->parent = initproc;
    8000264a:	00007a17          	auipc	s4,0x7
    8000264e:	a06a0a13          	addi	s4,s4,-1530 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002652:	00015997          	auipc	s3,0x15
    80002656:	4b698993          	addi	s3,s3,1206 # 80017b08 <tickslock>
    8000265a:	a029                	j	80002664 <reparent+0x34>
    8000265c:	19048493          	addi	s1,s1,400
    80002660:	01348d63          	beq	s1,s3,8000267a <reparent+0x4a>
    if(pp->parent == p){
    80002664:	70bc                	ld	a5,96(s1)
    80002666:	ff279be3          	bne	a5,s2,8000265c <reparent+0x2c>
      pp->parent = initproc;
    8000266a:	000a3503          	ld	a0,0(s4)
    8000266e:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002670:	00000097          	auipc	ra,0x0
    80002674:	f2c080e7          	jalr	-212(ra) # 8000259c <wakeup>
    80002678:	b7d5                	j	8000265c <reparent+0x2c>
}
    8000267a:	70a2                	ld	ra,40(sp)
    8000267c:	7402                	ld	s0,32(sp)
    8000267e:	64e2                	ld	s1,24(sp)
    80002680:	6942                	ld	s2,16(sp)
    80002682:	69a2                	ld	s3,8(sp)
    80002684:	6a02                	ld	s4,0(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret

000000008000268a <exit>:
{
    8000268a:	7179                	addi	sp,sp,-48
    8000268c:	f406                	sd	ra,40(sp)
    8000268e:	f022                	sd	s0,32(sp)
    80002690:	ec26                	sd	s1,24(sp)
    80002692:	e84a                	sd	s2,16(sp)
    80002694:	e44e                	sd	s3,8(sp)
    80002696:	e052                	sd	s4,0(sp)
    80002698:	1800                	addi	s0,sp,48
    8000269a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	324080e7          	jalr	804(ra) # 800019c0 <myproc>
    800026a4:	892a                	mv	s2,a0
  if(p == initproc)
    800026a6:	00007797          	auipc	a5,0x7
    800026aa:	9aa7b783          	ld	a5,-1622(a5) # 80009050 <initproc>
    800026ae:	0f850493          	addi	s1,a0,248
    800026b2:	17850993          	addi	s3,a0,376
    800026b6:	02a79363          	bne	a5,a0,800026dc <exit+0x52>
    panic("init exiting");
    800026ba:	00006517          	auipc	a0,0x6
    800026be:	c6650513          	addi	a0,a0,-922 # 80008320 <digits+0x2e0>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	e7c080e7          	jalr	-388(ra) # 8000053e <panic>
      fileclose(f);
    800026ca:	00002097          	auipc	ra,0x2
    800026ce:	19c080e7          	jalr	412(ra) # 80004866 <fileclose>
      p->ofile[fd] = 0;
    800026d2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026d6:	04a1                	addi	s1,s1,8
    800026d8:	01348563          	beq	s1,s3,800026e2 <exit+0x58>
    if(p->ofile[fd]){
    800026dc:	6088                	ld	a0,0(s1)
    800026de:	f575                	bnez	a0,800026ca <exit+0x40>
    800026e0:	bfdd                	j	800026d6 <exit+0x4c>
  begin_op();
    800026e2:	00002097          	auipc	ra,0x2
    800026e6:	cb8080e7          	jalr	-840(ra) # 8000439a <begin_op>
  iput(p->cwd);
    800026ea:	17893503          	ld	a0,376(s2)
    800026ee:	00001097          	auipc	ra,0x1
    800026f2:	494080e7          	jalr	1172(ra) # 80003b82 <iput>
  end_op();
    800026f6:	00002097          	auipc	ra,0x2
    800026fa:	d24080e7          	jalr	-732(ra) # 8000441a <end_op>
  p->cwd = 0;
    800026fe:	16093c23          	sd	zero,376(s2)
  acquire(&wait_lock);
    80002702:	0000f497          	auipc	s1,0xf
    80002706:	bd648493          	addi	s1,s1,-1066 # 800112d8 <wait_lock>
    8000270a:	8526                	mv	a0,s1
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	4d8080e7          	jalr	1240(ra) # 80000be4 <acquire>
  reparent(p);
    80002714:	854a                	mv	a0,s2
    80002716:	00000097          	auipc	ra,0x0
    8000271a:	f1a080e7          	jalr	-230(ra) # 80002630 <reparent>
  wakeup(p->parent);
    8000271e:	06093503          	ld	a0,96(s2)
    80002722:	00000097          	auipc	ra,0x0
    80002726:	e7a080e7          	jalr	-390(ra) # 8000259c <wakeup>
  acquire(&p->lock);
    8000272a:	854a                	mv	a0,s2
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	4b8080e7          	jalr	1208(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002734:	03492623          	sw	s4,44(s2)
  update_process_timing_in_state(p, p->state);
    80002738:	01892583          	lw	a1,24(s2)
    8000273c:	854a                	mv	a0,s2
    8000273e:	00000097          	auipc	ra,0x0
    80002742:	ab8080e7          	jalr	-1352(ra) # 800021f6 <update_process_timing_in_state>
  p->state = ZOMBIE;
    80002746:	4795                	li	a5,5
    80002748:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	54a080e7          	jalr	1354(ra) # 80000c98 <release>
  num_of_processes++;
    80002756:	00007797          	auipc	a5,0x7
    8000275a:	8f278793          	addi	a5,a5,-1806 # 80009048 <num_of_processes>
    8000275e:	4390                	lw	a2,0(a5)
    80002760:	0016069b          	addiw	a3,a2,1
    80002764:	c394                	sw	a3,0(a5)
  running_processes_mean = ( (running_processes_mean * (num_of_processes - 1)) + p->running_time) / num_of_processes;
    80002766:	05892583          	lw	a1,88(s2)
    8000276a:	00007797          	auipc	a5,0x7
    8000276e:	8ce78793          	addi	a5,a5,-1842 # 80009038 <running_processes_mean>
    80002772:	4398                	lw	a4,0(a5)
    80002774:	02c7073b          	mulw	a4,a4,a2
    80002778:	9f2d                	addw	a4,a4,a1
    8000277a:	02d7573b          	divuw	a4,a4,a3
    8000277e:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ( (runnable_processes_mean * (num_of_processes - 1)) + p->runnable_time) / num_of_processes;
    80002780:	00007797          	auipc	a5,0x7
    80002784:	8b478793          	addi	a5,a5,-1868 # 80009034 <runnable_processes_mean>
    80002788:	4398                	lw	a4,0(a5)
    8000278a:	02c7073b          	mulw	a4,a4,a2
    8000278e:	05492503          	lw	a0,84(s2)
    80002792:	9f29                	addw	a4,a4,a0
    80002794:	02d7573b          	divuw	a4,a4,a3
    80002798:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ( (sleeping_processes_mean * (num_of_processes - 1)) + p->sleeping_time) / num_of_processes;
    8000279a:	00007717          	auipc	a4,0x7
    8000279e:	89670713          	addi	a4,a4,-1898 # 80009030 <sleeping_processes_mean>
    800027a2:	431c                	lw	a5,0(a4)
    800027a4:	02c787bb          	mulw	a5,a5,a2
    800027a8:	05092603          	lw	a2,80(s2)
    800027ac:	9fb1                	addw	a5,a5,a2
    800027ae:	02d7d7bb          	divuw	a5,a5,a3
    800027b2:	c31c                	sw	a5,0(a4)
  program_time += p->running_time;
    800027b4:	00007697          	auipc	a3,0x7
    800027b8:	89068693          	addi	a3,a3,-1904 # 80009044 <program_time>
    800027bc:	429c                	lw	a5,0(a3)
    800027be:	00b7873b          	addw	a4,a5,a1
    800027c2:	c298                	sw	a4,0(a3)
  cpu_utilization = ((program_time * 100) / (ticks - start_time));
    800027c4:	06400793          	li	a5,100
    800027c8:	02e787bb          	mulw	a5,a5,a4
    800027cc:	00007717          	auipc	a4,0x7
    800027d0:	88c72703          	lw	a4,-1908(a4) # 80009058 <ticks>
    800027d4:	00007697          	auipc	a3,0x7
    800027d8:	8686a683          	lw	a3,-1944(a3) # 8000903c <start_time>
    800027dc:	9f15                	subw	a4,a4,a3
    800027de:	02e7d7bb          	divuw	a5,a5,a4
    800027e2:	00007717          	auipc	a4,0x7
    800027e6:	84f72f23          	sw	a5,-1954(a4) # 80009040 <cpu_utilization>
  sched();
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	72e080e7          	jalr	1838(ra) # 80001f18 <sched>
  panic("zombie exit");
    800027f2:	00006517          	auipc	a0,0x6
    800027f6:	b3e50513          	addi	a0,a0,-1218 # 80008330 <digits+0x2f0>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d44080e7          	jalr	-700(ra) # 8000053e <panic>

0000000080002802 <kill>:
{
    80002802:	7179                	addi	sp,sp,-48
    80002804:	f406                	sd	ra,40(sp)
    80002806:	f022                	sd	s0,32(sp)
    80002808:	ec26                	sd	s1,24(sp)
    8000280a:	e84a                	sd	s2,16(sp)
    8000280c:	e44e                	sd	s3,8(sp)
    8000280e:	1800                	addi	s0,sp,48
    80002810:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002812:	0000f497          	auipc	s1,0xf
    80002816:	ef648493          	addi	s1,s1,-266 # 80011708 <proc>
    8000281a:	00015997          	auipc	s3,0x15
    8000281e:	2ee98993          	addi	s3,s3,750 # 80017b08 <tickslock>
    acquire(&p->lock);
    80002822:	8526                	mv	a0,s1
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	3c0080e7          	jalr	960(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000282c:	589c                	lw	a5,48(s1)
    8000282e:	01278d63          	beq	a5,s2,80002848 <kill+0x46>
    release(&p->lock);
    80002832:	8526                	mv	a0,s1
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	464080e7          	jalr	1124(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000283c:	19048493          	addi	s1,s1,400
    80002840:	ff3491e3          	bne	s1,s3,80002822 <kill+0x20>
  return -1;
    80002844:	557d                	li	a0,-1
    80002846:	a829                	j	80002860 <kill+0x5e>
      p->killed = 1;
    80002848:	4785                	li	a5,1
    8000284a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000284c:	4c98                	lw	a4,24(s1)
    8000284e:	4789                	li	a5,2
    80002850:	00f70f63          	beq	a4,a5,8000286e <kill+0x6c>
      release(&p->lock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	442080e7          	jalr	1090(ra) # 80000c98 <release>
      return 0;
    8000285e:	4501                	li	a0,0
}
    80002860:	70a2                	ld	ra,40(sp)
    80002862:	7402                	ld	s0,32(sp)
    80002864:	64e2                	ld	s1,24(sp)
    80002866:	6942                	ld	s2,16(sp)
    80002868:	69a2                	ld	s3,8(sp)
    8000286a:	6145                	addi	sp,sp,48
    8000286c:	8082                	ret
        update_process_timing_in_state(p, p->state);
    8000286e:	4589                	li	a1,2
    80002870:	8526                	mv	a0,s1
    80002872:	00000097          	auipc	ra,0x0
    80002876:	984080e7          	jalr	-1660(ra) # 800021f6 <update_process_timing_in_state>
        p->state = RUNNABLE;
    8000287a:	478d                	li	a5,3
    8000287c:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    8000287e:	00006797          	auipc	a5,0x6
    80002882:	7da7e783          	lwu	a5,2010(a5) # 80009058 <ticks>
    80002886:	fc9c                	sd	a5,56(s1)
    80002888:	b7f1                	j	80002854 <kill+0x52>

000000008000288a <kill_system>:
int kill_system(void){	//maybe check we don't kill ourselves first
    8000288a:	7139                	addi	sp,sp,-64
    8000288c:	fc06                	sd	ra,56(sp)
    8000288e:	f822                	sd	s0,48(sp)
    80002890:	f426                	sd	s1,40(sp)
    80002892:	f04a                	sd	s2,32(sp)
    80002894:	ec4e                	sd	s3,24(sp)
    80002896:	e852                	sd	s4,16(sp)
    80002898:	e456                	sd	s5,8(sp)
    8000289a:	0080                	addi	s0,sp,64
  struct proc *cur = myproc();
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	124080e7          	jalr	292(ra) # 800019c0 <myproc>
    800028a4:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    800028a6:	0000f497          	auipc	s1,0xf
    800028aa:	e6248493          	addi	s1,s1,-414 # 80011708 <proc>
    if(p->pid != cur->pid && p->pid != INIT_PROC_PID && p->pid != SHELL_PROC_PID){
    800028ae:	4a05                	li	s4,1
      if(kill(p->pid) == -1){
    800028b0:	5afd                	li	s5,-1
  for(p = proc; p < &proc[NPROC]; p++){
    800028b2:	00015997          	auipc	s3,0x15
    800028b6:	25698993          	addi	s3,s3,598 # 80017b08 <tickslock>
    800028ba:	a029                	j	800028c4 <kill_system+0x3a>
    800028bc:	19048493          	addi	s1,s1,400
    800028c0:	03348263          	beq	s1,s3,800028e4 <kill_system+0x5a>
    if(p->pid != cur->pid && p->pid != INIT_PROC_PID && p->pid != SHELL_PROC_PID){
    800028c4:	5888                	lw	a0,48(s1)
    800028c6:	03092783          	lw	a5,48(s2)
    800028ca:	fea789e3          	beq	a5,a0,800028bc <kill_system+0x32>
    800028ce:	fff5079b          	addiw	a5,a0,-1
    800028d2:	fefa75e3          	bgeu	s4,a5,800028bc <kill_system+0x32>
      if(kill(p->pid) == -1){
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	f2c080e7          	jalr	-212(ra) # 80002802 <kill>
    800028de:	fd551fe3          	bne	a0,s5,800028bc <kill_system+0x32>
    800028e2:	a039                	j	800028f0 <kill_system+0x66>
	return kill(cur->pid);
    800028e4:	03092503          	lw	a0,48(s2)
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	f1a080e7          	jalr	-230(ra) # 80002802 <kill>
}
    800028f0:	70e2                	ld	ra,56(sp)
    800028f2:	7442                	ld	s0,48(sp)
    800028f4:	74a2                	ld	s1,40(sp)
    800028f6:	7902                	ld	s2,32(sp)
    800028f8:	69e2                	ld	s3,24(sp)
    800028fa:	6a42                	ld	s4,16(sp)
    800028fc:	6aa2                	ld	s5,8(sp)
    800028fe:	6121                	addi	sp,sp,64
    80002900:	8082                	ret

0000000080002902 <swtch>:
    80002902:	00153023          	sd	ra,0(a0)
    80002906:	00253423          	sd	sp,8(a0)
    8000290a:	e900                	sd	s0,16(a0)
    8000290c:	ed04                	sd	s1,24(a0)
    8000290e:	03253023          	sd	s2,32(a0)
    80002912:	03353423          	sd	s3,40(a0)
    80002916:	03453823          	sd	s4,48(a0)
    8000291a:	03553c23          	sd	s5,56(a0)
    8000291e:	05653023          	sd	s6,64(a0)
    80002922:	05753423          	sd	s7,72(a0)
    80002926:	05853823          	sd	s8,80(a0)
    8000292a:	05953c23          	sd	s9,88(a0)
    8000292e:	07a53023          	sd	s10,96(a0)
    80002932:	07b53423          	sd	s11,104(a0)
    80002936:	0005b083          	ld	ra,0(a1)
    8000293a:	0085b103          	ld	sp,8(a1)
    8000293e:	6980                	ld	s0,16(a1)
    80002940:	6d84                	ld	s1,24(a1)
    80002942:	0205b903          	ld	s2,32(a1)
    80002946:	0285b983          	ld	s3,40(a1)
    8000294a:	0305ba03          	ld	s4,48(a1)
    8000294e:	0385ba83          	ld	s5,56(a1)
    80002952:	0405bb03          	ld	s6,64(a1)
    80002956:	0485bb83          	ld	s7,72(a1)
    8000295a:	0505bc03          	ld	s8,80(a1)
    8000295e:	0585bc83          	ld	s9,88(a1)
    80002962:	0605bd03          	ld	s10,96(a1)
    80002966:	0685bd83          	ld	s11,104(a1)
    8000296a:	8082                	ret

000000008000296c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000296c:	1141                	addi	sp,sp,-16
    8000296e:	e406                	sd	ra,8(sp)
    80002970:	e022                	sd	s0,0(sp)
    80002972:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002974:	00006597          	auipc	a1,0x6
    80002978:	a2458593          	addi	a1,a1,-1500 # 80008398 <states.1739+0x30>
    8000297c:	00015517          	auipc	a0,0x15
    80002980:	18c50513          	addi	a0,a0,396 # 80017b08 <tickslock>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	1d0080e7          	jalr	464(ra) # 80000b54 <initlock>
}
    8000298c:	60a2                	ld	ra,8(sp)
    8000298e:	6402                	ld	s0,0(sp)
    80002990:	0141                	addi	sp,sp,16
    80002992:	8082                	ret

0000000080002994 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002994:	1141                	addi	sp,sp,-16
    80002996:	e422                	sd	s0,8(sp)
    80002998:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000299a:	00003797          	auipc	a5,0x3
    8000299e:	4e678793          	addi	a5,a5,1254 # 80005e80 <kernelvec>
    800029a2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029a6:	6422                	ld	s0,8(sp)
    800029a8:	0141                	addi	sp,sp,16
    800029aa:	8082                	ret

00000000800029ac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029ac:	1141                	addi	sp,sp,-16
    800029ae:	e406                	sd	ra,8(sp)
    800029b0:	e022                	sd	s0,0(sp)
    800029b2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	00c080e7          	jalr	12(ra) # 800019c0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029c0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029c6:	00004617          	auipc	a2,0x4
    800029ca:	63a60613          	addi	a2,a2,1594 # 80007000 <_trampoline>
    800029ce:	00004697          	auipc	a3,0x4
    800029d2:	63268693          	addi	a3,a3,1586 # 80007000 <_trampoline>
    800029d6:	8e91                	sub	a3,a3,a2
    800029d8:	040007b7          	lui	a5,0x4000
    800029dc:	17fd                	addi	a5,a5,-1
    800029de:	07b2                	slli	a5,a5,0xc
    800029e0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029e6:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e8:	180026f3          	csrr	a3,satp
    800029ec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029ee:	6158                	ld	a4,128(a0)
    800029f0:	7534                	ld	a3,104(a0)
    800029f2:	6585                	lui	a1,0x1
    800029f4:	96ae                	add	a3,a3,a1
    800029f6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f8:	6158                	ld	a4,128(a0)
    800029fa:	00000697          	auipc	a3,0x0
    800029fe:	13868693          	addi	a3,a3,312 # 80002b32 <usertrap>
    80002a02:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a04:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a06:	8692                	mv	a3,tp
    80002a08:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a0e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a12:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a16:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a1a:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1c:	6f18                	ld	a4,24(a4)
    80002a1e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a22:	7d2c                	ld	a1,120(a0)
    80002a24:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a26:	00004717          	auipc	a4,0x4
    80002a2a:	66a70713          	addi	a4,a4,1642 # 80007090 <userret>
    80002a2e:	8f11                	sub	a4,a4,a2
    80002a30:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a32:	577d                	li	a4,-1
    80002a34:	177e                	slli	a4,a4,0x3f
    80002a36:	8dd9                	or	a1,a1,a4
    80002a38:	02000537          	lui	a0,0x2000
    80002a3c:	157d                	addi	a0,a0,-1
    80002a3e:	0536                	slli	a0,a0,0xd
    80002a40:	9782                	jalr	a5
}
    80002a42:	60a2                	ld	ra,8(sp)
    80002a44:	6402                	ld	s0,0(sp)
    80002a46:	0141                	addi	sp,sp,16
    80002a48:	8082                	ret

0000000080002a4a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a4a:	1101                	addi	sp,sp,-32
    80002a4c:	ec06                	sd	ra,24(sp)
    80002a4e:	e822                	sd	s0,16(sp)
    80002a50:	e426                	sd	s1,8(sp)
    80002a52:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a54:	00015497          	auipc	s1,0x15
    80002a58:	0b448493          	addi	s1,s1,180 # 80017b08 <tickslock>
    80002a5c:	8526                	mv	a0,s1
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	186080e7          	jalr	390(ra) # 80000be4 <acquire>
  ticks++;
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	5f250513          	addi	a0,a0,1522 # 80009058 <ticks>
    80002a6e:	411c                	lw	a5,0(a0)
    80002a70:	2785                	addiw	a5,a5,1
    80002a72:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	b28080e7          	jalr	-1240(ra) # 8000259c <wakeup>
  release(&tickslock);
    80002a7c:	8526                	mv	a0,s1
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	21a080e7          	jalr	538(ra) # 80000c98 <release>
}
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret

0000000080002a90 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a90:	1101                	addi	sp,sp,-32
    80002a92:	ec06                	sd	ra,24(sp)
    80002a94:	e822                	sd	s0,16(sp)
    80002a96:	e426                	sd	s1,8(sp)
    80002a98:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a9a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a9e:	00074d63          	bltz	a4,80002ab8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aa2:	57fd                	li	a5,-1
    80002aa4:	17fe                	slli	a5,a5,0x3f
    80002aa6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aa8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aaa:	06f70363          	beq	a4,a5,80002b10 <devintr+0x80>
  }
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret
     (scause & 0xff) == 9){
    80002ab8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002abc:	46a5                	li	a3,9
    80002abe:	fed792e3          	bne	a5,a3,80002aa2 <devintr+0x12>
    int irq = plic_claim();
    80002ac2:	00003097          	auipc	ra,0x3
    80002ac6:	4c6080e7          	jalr	1222(ra) # 80005f88 <plic_claim>
    80002aca:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002acc:	47a9                	li	a5,10
    80002ace:	02f50763          	beq	a0,a5,80002afc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ad2:	4785                	li	a5,1
    80002ad4:	02f50963          	beq	a0,a5,80002b06 <devintr+0x76>
    return 1;
    80002ad8:	4505                	li	a0,1
    } else if(irq){
    80002ada:	d8f1                	beqz	s1,80002aae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002adc:	85a6                	mv	a1,s1
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	8c250513          	addi	a0,a0,-1854 # 800083a0 <states.1739+0x38>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	aa2080e7          	jalr	-1374(ra) # 80000588 <printf>
      plic_complete(irq);
    80002aee:	8526                	mv	a0,s1
    80002af0:	00003097          	auipc	ra,0x3
    80002af4:	4bc080e7          	jalr	1212(ra) # 80005fac <plic_complete>
    return 1;
    80002af8:	4505                	li	a0,1
    80002afa:	bf55                	j	80002aae <devintr+0x1e>
      uartintr();
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	eac080e7          	jalr	-340(ra) # 800009a8 <uartintr>
    80002b04:	b7ed                	j	80002aee <devintr+0x5e>
      virtio_disk_intr();
    80002b06:	00004097          	auipc	ra,0x4
    80002b0a:	986080e7          	jalr	-1658(ra) # 8000648c <virtio_disk_intr>
    80002b0e:	b7c5                	j	80002aee <devintr+0x5e>
    if(cpuid() == 0){
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	e84080e7          	jalr	-380(ra) # 80001994 <cpuid>
    80002b18:	c901                	beqz	a0,80002b28 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b1a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b20:	14479073          	csrw	sip,a5
    return 2;
    80002b24:	4509                	li	a0,2
    80002b26:	b761                	j	80002aae <devintr+0x1e>
      clockintr();
    80002b28:	00000097          	auipc	ra,0x0
    80002b2c:	f22080e7          	jalr	-222(ra) # 80002a4a <clockintr>
    80002b30:	b7ed                	j	80002b1a <devintr+0x8a>

0000000080002b32 <usertrap>:
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	e04a                	sd	s2,0(sp)
    80002b3c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b42:	1007f793          	andi	a5,a5,256
    80002b46:	e3ad                	bnez	a5,80002ba8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b48:	00003797          	auipc	a5,0x3
    80002b4c:	33878793          	addi	a5,a5,824 # 80005e80 <kernelvec>
    80002b50:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	e6c080e7          	jalr	-404(ra) # 800019c0 <myproc>
    80002b5c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b5e:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b60:	14102773          	csrr	a4,sepc
    80002b64:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b66:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b6a:	47a1                	li	a5,8
    80002b6c:	04f71c63          	bne	a4,a5,80002bc4 <usertrap+0x92>
    if(p->killed)
    80002b70:	551c                	lw	a5,40(a0)
    80002b72:	e3b9                	bnez	a5,80002bb8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b74:	60d8                	ld	a4,128(s1)
    80002b76:	6f1c                	ld	a5,24(a4)
    80002b78:	0791                	addi	a5,a5,4
    80002b7a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b80:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b84:	10079073          	csrw	sstatus,a5
    syscall();
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	2e0080e7          	jalr	736(ra) # 80002e68 <syscall>
  if(p->killed)
    80002b90:	549c                	lw	a5,40(s1)
    80002b92:	ebc1                	bnez	a5,80002c22 <usertrap+0xf0>
  usertrapret();
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	e18080e7          	jalr	-488(ra) # 800029ac <usertrapret>
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6902                	ld	s2,0(sp)
    80002ba4:	6105                	addi	sp,sp,32
    80002ba6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	81850513          	addi	a0,a0,-2024 # 800083c0 <states.1739+0x58>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
      exit(-1);
    80002bb8:	557d                	li	a0,-1
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	ad0080e7          	jalr	-1328(ra) # 8000268a <exit>
    80002bc2:	bf4d                	j	80002b74 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	ecc080e7          	jalr	-308(ra) # 80002a90 <devintr>
    80002bcc:	892a                	mv	s2,a0
    80002bce:	c501                	beqz	a0,80002bd6 <usertrap+0xa4>
  if(p->killed)
    80002bd0:	549c                	lw	a5,40(s1)
    80002bd2:	c3a1                	beqz	a5,80002c12 <usertrap+0xe0>
    80002bd4:	a815                	j	80002c08 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bda:	5890                	lw	a2,48(s1)
    80002bdc:	00006517          	auipc	a0,0x6
    80002be0:	80450513          	addi	a0,a0,-2044 # 800083e0 <states.1739+0x78>
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	9a4080e7          	jalr	-1628(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf4:	00006517          	auipc	a0,0x6
    80002bf8:	81c50513          	addi	a0,a0,-2020 # 80008410 <states.1739+0xa8>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	98c080e7          	jalr	-1652(ra) # 80000588 <printf>
    p->killed = 1;
    80002c04:	4785                	li	a5,1
    80002c06:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c08:	557d                	li	a0,-1
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	a80080e7          	jalr	-1408(ra) # 8000268a <exit>
  if(which_dev == 2)
    80002c12:	4789                	li	a5,2
    80002c14:	f8f910e3          	bne	s2,a5,80002b94 <usertrap+0x62>
    yield();
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	758080e7          	jalr	1880(ra) # 80002370 <yield>
    80002c20:	bf95                	j	80002b94 <usertrap+0x62>
  int which_dev = 0;
    80002c22:	4901                	li	s2,0
    80002c24:	b7d5                	j	80002c08 <usertrap+0xd6>

0000000080002c26 <kerneltrap>:
{
    80002c26:	7179                	addi	sp,sp,-48
    80002c28:	f406                	sd	ra,40(sp)
    80002c2a:	f022                	sd	s0,32(sp)
    80002c2c:	ec26                	sd	s1,24(sp)
    80002c2e:	e84a                	sd	s2,16(sp)
    80002c30:	e44e                	sd	s3,8(sp)
    80002c32:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c34:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c38:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c3c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c40:	1004f793          	andi	a5,s1,256
    80002c44:	cb85                	beqz	a5,80002c74 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c46:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c4a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c4c:	ef85                	bnez	a5,80002c84 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	e42080e7          	jalr	-446(ra) # 80002a90 <devintr>
    80002c56:	cd1d                	beqz	a0,80002c94 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c58:	4789                	li	a5,2
    80002c5a:	06f50a63          	beq	a0,a5,80002cce <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c5e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c62:	10049073          	csrw	sstatus,s1
}
    80002c66:	70a2                	ld	ra,40(sp)
    80002c68:	7402                	ld	s0,32(sp)
    80002c6a:	64e2                	ld	s1,24(sp)
    80002c6c:	6942                	ld	s2,16(sp)
    80002c6e:	69a2                	ld	s3,8(sp)
    80002c70:	6145                	addi	sp,sp,48
    80002c72:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	7bc50513          	addi	a0,a0,1980 # 80008430 <states.1739+0xc8>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	8c2080e7          	jalr	-1854(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	7d450513          	addi	a0,a0,2004 # 80008458 <states.1739+0xf0>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8b2080e7          	jalr	-1870(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c94:	85ce                	mv	a1,s3
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	7e250513          	addi	a0,a0,2018 # 80008478 <states.1739+0x110>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ea080e7          	jalr	-1814(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002caa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cae:	00005517          	auipc	a0,0x5
    80002cb2:	7da50513          	addi	a0,a0,2010 # 80008488 <states.1739+0x120>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	8d2080e7          	jalr	-1838(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	7e250513          	addi	a0,a0,2018 # 800084a0 <states.1739+0x138>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	878080e7          	jalr	-1928(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	cf2080e7          	jalr	-782(ra) # 800019c0 <myproc>
    80002cd6:	d541                	beqz	a0,80002c5e <kerneltrap+0x38>
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	ce8080e7          	jalr	-792(ra) # 800019c0 <myproc>
    80002ce0:	4d18                	lw	a4,24(a0)
    80002ce2:	4791                	li	a5,4
    80002ce4:	f6f71de3          	bne	a4,a5,80002c5e <kerneltrap+0x38>
    yield();
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	688080e7          	jalr	1672(ra) # 80002370 <yield>
    80002cf0:	b7bd                	j	80002c5e <kerneltrap+0x38>

0000000080002cf2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	1000                	addi	s0,sp,32
    80002cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	cc2080e7          	jalr	-830(ra) # 800019c0 <myproc>
  switch (n) {
    80002d06:	4795                	li	a5,5
    80002d08:	0497e163          	bltu	a5,s1,80002d4a <argraw+0x58>
    80002d0c:	048a                	slli	s1,s1,0x2
    80002d0e:	00005717          	auipc	a4,0x5
    80002d12:	7ca70713          	addi	a4,a4,1994 # 800084d8 <states.1739+0x170>
    80002d16:	94ba                	add	s1,s1,a4
    80002d18:	409c                	lw	a5,0(s1)
    80002d1a:	97ba                	add	a5,a5,a4
    80002d1c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d1e:	615c                	ld	a5,128(a0)
    80002d20:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d22:	60e2                	ld	ra,24(sp)
    80002d24:	6442                	ld	s0,16(sp)
    80002d26:	64a2                	ld	s1,8(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret
    return p->trapframe->a1;
    80002d2c:	615c                	ld	a5,128(a0)
    80002d2e:	7fa8                	ld	a0,120(a5)
    80002d30:	bfcd                	j	80002d22 <argraw+0x30>
    return p->trapframe->a2;
    80002d32:	615c                	ld	a5,128(a0)
    80002d34:	63c8                	ld	a0,128(a5)
    80002d36:	b7f5                	j	80002d22 <argraw+0x30>
    return p->trapframe->a3;
    80002d38:	615c                	ld	a5,128(a0)
    80002d3a:	67c8                	ld	a0,136(a5)
    80002d3c:	b7dd                	j	80002d22 <argraw+0x30>
    return p->trapframe->a4;
    80002d3e:	615c                	ld	a5,128(a0)
    80002d40:	6bc8                	ld	a0,144(a5)
    80002d42:	b7c5                	j	80002d22 <argraw+0x30>
    return p->trapframe->a5;
    80002d44:	615c                	ld	a5,128(a0)
    80002d46:	6fc8                	ld	a0,152(a5)
    80002d48:	bfe9                	j	80002d22 <argraw+0x30>
  panic("argraw");
    80002d4a:	00005517          	auipc	a0,0x5
    80002d4e:	76650513          	addi	a0,a0,1894 # 800084b0 <states.1739+0x148>
    80002d52:	ffffd097          	auipc	ra,0xffffd
    80002d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>

0000000080002d5a <fetchaddr>:
{
    80002d5a:	1101                	addi	sp,sp,-32
    80002d5c:	ec06                	sd	ra,24(sp)
    80002d5e:	e822                	sd	s0,16(sp)
    80002d60:	e426                	sd	s1,8(sp)
    80002d62:	e04a                	sd	s2,0(sp)
    80002d64:	1000                	addi	s0,sp,32
    80002d66:	84aa                	mv	s1,a0
    80002d68:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	c56080e7          	jalr	-938(ra) # 800019c0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d72:	793c                	ld	a5,112(a0)
    80002d74:	02f4f863          	bgeu	s1,a5,80002da4 <fetchaddr+0x4a>
    80002d78:	00848713          	addi	a4,s1,8
    80002d7c:	02e7e663          	bltu	a5,a4,80002da8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d80:	46a1                	li	a3,8
    80002d82:	8626                	mv	a2,s1
    80002d84:	85ca                	mv	a1,s2
    80002d86:	7d28                	ld	a0,120(a0)
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	976080e7          	jalr	-1674(ra) # 800016fe <copyin>
    80002d90:	00a03533          	snez	a0,a0
    80002d94:	40a00533          	neg	a0,a0
}
    80002d98:	60e2                	ld	ra,24(sp)
    80002d9a:	6442                	ld	s0,16(sp)
    80002d9c:	64a2                	ld	s1,8(sp)
    80002d9e:	6902                	ld	s2,0(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret
    return -1;
    80002da4:	557d                	li	a0,-1
    80002da6:	bfcd                	j	80002d98 <fetchaddr+0x3e>
    80002da8:	557d                	li	a0,-1
    80002daa:	b7fd                	j	80002d98 <fetchaddr+0x3e>

0000000080002dac <fetchstr>:
{
    80002dac:	7179                	addi	sp,sp,-48
    80002dae:	f406                	sd	ra,40(sp)
    80002db0:	f022                	sd	s0,32(sp)
    80002db2:	ec26                	sd	s1,24(sp)
    80002db4:	e84a                	sd	s2,16(sp)
    80002db6:	e44e                	sd	s3,8(sp)
    80002db8:	1800                	addi	s0,sp,48
    80002dba:	892a                	mv	s2,a0
    80002dbc:	84ae                	mv	s1,a1
    80002dbe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	c00080e7          	jalr	-1024(ra) # 800019c0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dc8:	86ce                	mv	a3,s3
    80002dca:	864a                	mv	a2,s2
    80002dcc:	85a6                	mv	a1,s1
    80002dce:	7d28                	ld	a0,120(a0)
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	9ba080e7          	jalr	-1606(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002dd8:	00054763          	bltz	a0,80002de6 <fetchstr+0x3a>
  return strlen(buf);
    80002ddc:	8526                	mv	a0,s1
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	086080e7          	jalr	134(ra) # 80000e64 <strlen>
}
    80002de6:	70a2                	ld	ra,40(sp)
    80002de8:	7402                	ld	s0,32(sp)
    80002dea:	64e2                	ld	s1,24(sp)
    80002dec:	6942                	ld	s2,16(sp)
    80002dee:	69a2                	ld	s3,8(sp)
    80002df0:	6145                	addi	sp,sp,48
    80002df2:	8082                	ret

0000000080002df4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	e426                	sd	s1,8(sp)
    80002dfc:	1000                	addi	s0,sp,32
    80002dfe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	ef2080e7          	jalr	-270(ra) # 80002cf2 <argraw>
    80002e08:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e0a:	4501                	li	a0,0
    80002e0c:	60e2                	ld	ra,24(sp)
    80002e0e:	6442                	ld	s0,16(sp)
    80002e10:	64a2                	ld	s1,8(sp)
    80002e12:	6105                	addi	sp,sp,32
    80002e14:	8082                	ret

0000000080002e16 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	1000                	addi	s0,sp,32
    80002e20:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	ed0080e7          	jalr	-304(ra) # 80002cf2 <argraw>
    80002e2a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e2c:	4501                	li	a0,0
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	64a2                	ld	s1,8(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e38:	1101                	addi	sp,sp,-32
    80002e3a:	ec06                	sd	ra,24(sp)
    80002e3c:	e822                	sd	s0,16(sp)
    80002e3e:	e426                	sd	s1,8(sp)
    80002e40:	e04a                	sd	s2,0(sp)
    80002e42:	1000                	addi	s0,sp,32
    80002e44:	84ae                	mv	s1,a1
    80002e46:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	eaa080e7          	jalr	-342(ra) # 80002cf2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e50:	864a                	mv	a2,s2
    80002e52:	85a6                	mv	a1,s1
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	f58080e7          	jalr	-168(ra) # 80002dac <fetchstr>
}
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	64a2                	ld	s1,8(sp)
    80002e62:	6902                	ld	s2,0(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <syscall>:
[SYS_print_stats]   sys_print_stats //* 
};

void
syscall(void)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	e426                	sd	s1,8(sp)
    80002e70:	e04a                	sd	s2,0(sp)
    80002e72:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	b4c080e7          	jalr	-1204(ra) # 800019c0 <myproc>
    80002e7c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e7e:	08053903          	ld	s2,128(a0)
    80002e82:	0a893783          	ld	a5,168(s2)
    80002e86:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e8a:	37fd                	addiw	a5,a5,-1
    80002e8c:	475d                	li	a4,23
    80002e8e:	00f76f63          	bltu	a4,a5,80002eac <syscall+0x44>
    80002e92:	00369713          	slli	a4,a3,0x3
    80002e96:	00005797          	auipc	a5,0x5
    80002e9a:	65a78793          	addi	a5,a5,1626 # 800084f0 <syscalls>
    80002e9e:	97ba                	add	a5,a5,a4
    80002ea0:	639c                	ld	a5,0(a5)
    80002ea2:	c789                	beqz	a5,80002eac <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ea4:	9782                	jalr	a5
    80002ea6:	06a93823          	sd	a0,112(s2)
    80002eaa:	a839                	j	80002ec8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eac:	18048613          	addi	a2,s1,384
    80002eb0:	588c                	lw	a1,48(s1)
    80002eb2:	00005517          	auipc	a0,0x5
    80002eb6:	60650513          	addi	a0,a0,1542 # 800084b8 <states.1739+0x150>
    80002eba:	ffffd097          	auipc	ra,0xffffd
    80002ebe:	6ce080e7          	jalr	1742(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec2:	60dc                	ld	a5,128(s1)
    80002ec4:	577d                	li	a4,-1
    80002ec6:	fbb8                	sd	a4,112(a5)
  }
}
    80002ec8:	60e2                	ld	ra,24(sp)
    80002eca:	6442                	ld	s0,16(sp)
    80002ecc:	64a2                	ld	s1,8(sp)
    80002ece:	6902                	ld	s2,0(sp)
    80002ed0:	6105                	addi	sp,sp,32
    80002ed2:	8082                	ret

0000000080002ed4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002edc:	fec40593          	addi	a1,s0,-20
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	f12080e7          	jalr	-238(ra) # 80002df4 <argint>
    return -1;
    80002eea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eec:	00054963          	bltz	a0,80002efe <sys_exit+0x2a>
  exit(n);
    80002ef0:	fec42503          	lw	a0,-20(s0)
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	796080e7          	jalr	1942(ra) # 8000268a <exit>
  return 0;  // not reached
    80002efc:	4781                	li	a5,0
}
    80002efe:	853e                	mv	a0,a5
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f08:	1141                	addi	sp,sp,-16
    80002f0a:	e406                	sd	ra,8(sp)
    80002f0c:	e022                	sd	s0,0(sp)
    80002f0e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	ab0080e7          	jalr	-1360(ra) # 800019c0 <myproc>
}
    80002f18:	5908                	lw	a0,48(a0)
    80002f1a:	60a2                	ld	ra,8(sp)
    80002f1c:	6402                	ld	s0,0(sp)
    80002f1e:	0141                	addi	sp,sp,16
    80002f20:	8082                	ret

0000000080002f22 <sys_fork>:

uint64
sys_fork(void)
{
    80002f22:	1141                	addi	sp,sp,-16
    80002f24:	e406                	sd	ra,8(sp)
    80002f26:	e022                	sd	s0,0(sp)
    80002f28:	0800                	addi	s0,sp,16
  return fork();
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	e92080e7          	jalr	-366(ra) # 80001dbc <fork>
}
    80002f32:	60a2                	ld	ra,8(sp)
    80002f34:	6402                	ld	s0,0(sp)
    80002f36:	0141                	addi	sp,sp,16
    80002f38:	8082                	ret

0000000080002f3a <sys_wait>:

uint64
sys_wait(void)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f42:	fe840593          	addi	a1,s0,-24
    80002f46:	4501                	li	a0,0
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	ece080e7          	jalr	-306(ra) # 80002e16 <argaddr>
    80002f50:	87aa                	mv	a5,a0
    return -1;
    80002f52:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f54:	0007c863          	bltz	a5,80002f64 <sys_wait+0x2a>
  return wait(p);
    80002f58:	fe843503          	ld	a0,-24(s0)
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	518080e7          	jalr	1304(ra) # 80002474 <wait>
}
    80002f64:	60e2                	ld	ra,24(sp)
    80002f66:	6442                	ld	s0,16(sp)
    80002f68:	6105                	addi	sp,sp,32
    80002f6a:	8082                	ret

0000000080002f6c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f6c:	7179                	addi	sp,sp,-48
    80002f6e:	f406                	sd	ra,40(sp)
    80002f70:	f022                	sd	s0,32(sp)
    80002f72:	ec26                	sd	s1,24(sp)
    80002f74:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f76:	fdc40593          	addi	a1,s0,-36
    80002f7a:	4501                	li	a0,0
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	e78080e7          	jalr	-392(ra) # 80002df4 <argint>
    80002f84:	87aa                	mv	a5,a0
    return -1;
    80002f86:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f88:	0207c063          	bltz	a5,80002fa8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	a34080e7          	jalr	-1484(ra) # 800019c0 <myproc>
    80002f94:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80002f96:	fdc42503          	lw	a0,-36(s0)
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	dae080e7          	jalr	-594(ra) # 80001d48 <growproc>
    80002fa2:	00054863          	bltz	a0,80002fb2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fa6:	8526                	mv	a0,s1
}
    80002fa8:	70a2                	ld	ra,40(sp)
    80002faa:	7402                	ld	s0,32(sp)
    80002fac:	64e2                	ld	s1,24(sp)
    80002fae:	6145                	addi	sp,sp,48
    80002fb0:	8082                	ret
    return -1;
    80002fb2:	557d                	li	a0,-1
    80002fb4:	bfd5                	j	80002fa8 <sys_sbrk+0x3c>

0000000080002fb6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fb6:	7139                	addi	sp,sp,-64
    80002fb8:	fc06                	sd	ra,56(sp)
    80002fba:	f822                	sd	s0,48(sp)
    80002fbc:	f426                	sd	s1,40(sp)
    80002fbe:	f04a                	sd	s2,32(sp)
    80002fc0:	ec4e                	sd	s3,24(sp)
    80002fc2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc4:	fcc40593          	addi	a1,s0,-52
    80002fc8:	4501                	li	a0,0
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	e2a080e7          	jalr	-470(ra) # 80002df4 <argint>
    return -1;
    80002fd2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd4:	06054563          	bltz	a0,8000303e <sys_sleep+0x88>
  acquire(&tickslock);
    80002fd8:	00015517          	auipc	a0,0x15
    80002fdc:	b3050513          	addi	a0,a0,-1232 # 80017b08 <tickslock>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	c04080e7          	jalr	-1020(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002fe8:	00006917          	auipc	s2,0x6
    80002fec:	07092903          	lw	s2,112(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    80002ff0:	fcc42783          	lw	a5,-52(s0)
    80002ff4:	cf85                	beqz	a5,8000302c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ff6:	00015997          	auipc	s3,0x15
    80002ffa:	b1298993          	addi	s3,s3,-1262 # 80017b08 <tickslock>
    80002ffe:	00006497          	auipc	s1,0x6
    80003002:	05a48493          	addi	s1,s1,90 # 80009058 <ticks>
    if(myproc()->killed){
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	9ba080e7          	jalr	-1606(ra) # 800019c0 <myproc>
    8000300e:	551c                	lw	a5,40(a0)
    80003010:	ef9d                	bnez	a5,8000304e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003012:	85ce                	mv	a1,s3
    80003014:	8526                	mv	a0,s1
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	3ee080e7          	jalr	1006(ra) # 80002404 <sleep>
  while(ticks - ticks0 < n){
    8000301e:	409c                	lw	a5,0(s1)
    80003020:	412787bb          	subw	a5,a5,s2
    80003024:	fcc42703          	lw	a4,-52(s0)
    80003028:	fce7efe3          	bltu	a5,a4,80003006 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000302c:	00015517          	auipc	a0,0x15
    80003030:	adc50513          	addi	a0,a0,-1316 # 80017b08 <tickslock>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>
  return 0;
    8000303c:	4781                	li	a5,0
}
    8000303e:	853e                	mv	a0,a5
    80003040:	70e2                	ld	ra,56(sp)
    80003042:	7442                	ld	s0,48(sp)
    80003044:	74a2                	ld	s1,40(sp)
    80003046:	7902                	ld	s2,32(sp)
    80003048:	69e2                	ld	s3,24(sp)
    8000304a:	6121                	addi	sp,sp,64
    8000304c:	8082                	ret
      release(&tickslock);
    8000304e:	00015517          	auipc	a0,0x15
    80003052:	aba50513          	addi	a0,a0,-1350 # 80017b08 <tickslock>
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
      return -1;
    8000305e:	57fd                	li	a5,-1
    80003060:	bff9                	j	8000303e <sys_sleep+0x88>

0000000080003062 <sys_kill>:

uint64
sys_kill(void)
{
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000306a:	fec40593          	addi	a1,s0,-20
    8000306e:	4501                	li	a0,0
    80003070:	00000097          	auipc	ra,0x0
    80003074:	d84080e7          	jalr	-636(ra) # 80002df4 <argint>
    80003078:	87aa                	mv	a5,a0
    return -1;
    8000307a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000307c:	0007c863          	bltz	a5,8000308c <sys_kill+0x2a>
  return kill(pid);
    80003080:	fec42503          	lw	a0,-20(s0)
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	77e080e7          	jalr	1918(ra) # 80002802 <kill>
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	6105                	addi	sp,sp,32
    80003092:	8082                	ret

0000000080003094 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000309e:	00015517          	auipc	a0,0x15
    800030a2:	a6a50513          	addi	a0,a0,-1430 # 80017b08 <tickslock>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	b3e080e7          	jalr	-1218(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030ae:	00006497          	auipc	s1,0x6
    800030b2:	faa4a483          	lw	s1,-86(s1) # 80009058 <ticks>
  release(&tickslock);
    800030b6:	00015517          	auipc	a0,0x15
    800030ba:	a5250513          	addi	a0,a0,-1454 # 80017b08 <tickslock>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
  return xticks;
}
    800030c6:	02049513          	slli	a0,s1,0x20
    800030ca:	9101                	srli	a0,a0,0x20
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <sys_pause_system>:

uint64
sys_pause_system(void)		//*
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	1000                	addi	s0,sp,32
	int seconds;
	if(argint(0, &seconds) < 0)
    800030de:	fec40593          	addi	a1,s0,-20
    800030e2:	4501                	li	a0,0
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	d10080e7          	jalr	-752(ra) # 80002df4 <argint>
    800030ec:	87aa                	mv	a5,a0
		return -1;
    800030ee:	557d                	li	a0,-1
	if(argint(0, &seconds) < 0)
    800030f0:	0007c863          	bltz	a5,80003100 <sys_pause_system+0x2a>
	return pause_system(seconds);
    800030f4:	fec42503          	lw	a0,-20(s0)
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	2ca080e7          	jalr	714(ra) # 800023c2 <pause_system>
}
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret

0000000080003108 <sys_kill_system>:

uint64
sys_kill_system(void)		//*
{
    80003108:	1141                	addi	sp,sp,-16
    8000310a:	e406                	sd	ra,8(sp)
    8000310c:	e022                	sd	s0,0(sp)
    8000310e:	0800                	addi	s0,sp,16
	return kill_system();
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	77a080e7          	jalr	1914(ra) # 8000288a <kill_system>
}
    80003118:	60a2                	ld	ra,8(sp)
    8000311a:	6402                	ld	s0,0(sp)
    8000311c:	0141                	addi	sp,sp,16
    8000311e:	8082                	ret

0000000080003120 <sys_print_stats>:

uint64
sys_print_stats(void)   //*
{
    80003120:	1141                	addi	sp,sp,-16
    80003122:	e406                	sd	ra,8(sp)
    80003124:	e022                	sd	s0,0(sp)
    80003126:	0800                	addi	s0,sp,16
  return print_stats();
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	020080e7          	jalr	32(ra) # 80002148 <print_stats>
}
    80003130:	60a2                	ld	ra,8(sp)
    80003132:	6402                	ld	s0,0(sp)
    80003134:	0141                	addi	sp,sp,16
    80003136:	8082                	ret

0000000080003138 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003138:	7179                	addi	sp,sp,-48
    8000313a:	f406                	sd	ra,40(sp)
    8000313c:	f022                	sd	s0,32(sp)
    8000313e:	ec26                	sd	s1,24(sp)
    80003140:	e84a                	sd	s2,16(sp)
    80003142:	e44e                	sd	s3,8(sp)
    80003144:	e052                	sd	s4,0(sp)
    80003146:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003148:	00005597          	auipc	a1,0x5
    8000314c:	47058593          	addi	a1,a1,1136 # 800085b8 <syscalls+0xc8>
    80003150:	00015517          	auipc	a0,0x15
    80003154:	9d050513          	addi	a0,a0,-1584 # 80017b20 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	9fc080e7          	jalr	-1540(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003160:	0001d797          	auipc	a5,0x1d
    80003164:	9c078793          	addi	a5,a5,-1600 # 8001fb20 <bcache+0x8000>
    80003168:	0001d717          	auipc	a4,0x1d
    8000316c:	c2070713          	addi	a4,a4,-992 # 8001fd88 <bcache+0x8268>
    80003170:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003174:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003178:	00015497          	auipc	s1,0x15
    8000317c:	9c048493          	addi	s1,s1,-1600 # 80017b38 <bcache+0x18>
    b->next = bcache.head.next;
    80003180:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003182:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003184:	00005a17          	auipc	s4,0x5
    80003188:	43ca0a13          	addi	s4,s4,1084 # 800085c0 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000318c:	2b893783          	ld	a5,696(s2)
    80003190:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003192:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003196:	85d2                	mv	a1,s4
    80003198:	01048513          	addi	a0,s1,16
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	4bc080e7          	jalr	1212(ra) # 80004658 <initsleeplock>
    bcache.head.next->prev = b;
    800031a4:	2b893783          	ld	a5,696(s2)
    800031a8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031aa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ae:	45848493          	addi	s1,s1,1112
    800031b2:	fd349de3          	bne	s1,s3,8000318c <binit+0x54>
  }
}
    800031b6:	70a2                	ld	ra,40(sp)
    800031b8:	7402                	ld	s0,32(sp)
    800031ba:	64e2                	ld	s1,24(sp)
    800031bc:	6942                	ld	s2,16(sp)
    800031be:	69a2                	ld	s3,8(sp)
    800031c0:	6a02                	ld	s4,0(sp)
    800031c2:	6145                	addi	sp,sp,48
    800031c4:	8082                	ret

00000000800031c6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031c6:	7179                	addi	sp,sp,-48
    800031c8:	f406                	sd	ra,40(sp)
    800031ca:	f022                	sd	s0,32(sp)
    800031cc:	ec26                	sd	s1,24(sp)
    800031ce:	e84a                	sd	s2,16(sp)
    800031d0:	e44e                	sd	s3,8(sp)
    800031d2:	1800                	addi	s0,sp,48
    800031d4:	89aa                	mv	s3,a0
    800031d6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031d8:	00015517          	auipc	a0,0x15
    800031dc:	94850513          	addi	a0,a0,-1720 # 80017b20 <bcache>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	a04080e7          	jalr	-1532(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031e8:	0001d497          	auipc	s1,0x1d
    800031ec:	bf04b483          	ld	s1,-1040(s1) # 8001fdd8 <bcache+0x82b8>
    800031f0:	0001d797          	auipc	a5,0x1d
    800031f4:	b9878793          	addi	a5,a5,-1128 # 8001fd88 <bcache+0x8268>
    800031f8:	02f48f63          	beq	s1,a5,80003236 <bread+0x70>
    800031fc:	873e                	mv	a4,a5
    800031fe:	a021                	j	80003206 <bread+0x40>
    80003200:	68a4                	ld	s1,80(s1)
    80003202:	02e48a63          	beq	s1,a4,80003236 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003206:	449c                	lw	a5,8(s1)
    80003208:	ff379ce3          	bne	a5,s3,80003200 <bread+0x3a>
    8000320c:	44dc                	lw	a5,12(s1)
    8000320e:	ff2799e3          	bne	a5,s2,80003200 <bread+0x3a>
      b->refcnt++;
    80003212:	40bc                	lw	a5,64(s1)
    80003214:	2785                	addiw	a5,a5,1
    80003216:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003218:	00015517          	auipc	a0,0x15
    8000321c:	90850513          	addi	a0,a0,-1784 # 80017b20 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003228:	01048513          	addi	a0,s1,16
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	466080e7          	jalr	1126(ra) # 80004692 <acquiresleep>
      return b;
    80003234:	a8b9                	j	80003292 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003236:	0001d497          	auipc	s1,0x1d
    8000323a:	b9a4b483          	ld	s1,-1126(s1) # 8001fdd0 <bcache+0x82b0>
    8000323e:	0001d797          	auipc	a5,0x1d
    80003242:	b4a78793          	addi	a5,a5,-1206 # 8001fd88 <bcache+0x8268>
    80003246:	00f48863          	beq	s1,a5,80003256 <bread+0x90>
    8000324a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000324c:	40bc                	lw	a5,64(s1)
    8000324e:	cf81                	beqz	a5,80003266 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003250:	64a4                	ld	s1,72(s1)
    80003252:	fee49de3          	bne	s1,a4,8000324c <bread+0x86>
  panic("bget: no buffers");
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	37250513          	addi	a0,a0,882 # 800085c8 <syscalls+0xd8>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>
      b->dev = dev;
    80003266:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000326a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000326e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003272:	4785                	li	a5,1
    80003274:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003276:	00015517          	auipc	a0,0x15
    8000327a:	8aa50513          	addi	a0,a0,-1878 # 80017b20 <bcache>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	a1a080e7          	jalr	-1510(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003286:	01048513          	addi	a0,s1,16
    8000328a:	00001097          	auipc	ra,0x1
    8000328e:	408080e7          	jalr	1032(ra) # 80004692 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003292:	409c                	lw	a5,0(s1)
    80003294:	cb89                	beqz	a5,800032a6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003296:	8526                	mv	a0,s1
    80003298:	70a2                	ld	ra,40(sp)
    8000329a:	7402                	ld	s0,32(sp)
    8000329c:	64e2                	ld	s1,24(sp)
    8000329e:	6942                	ld	s2,16(sp)
    800032a0:	69a2                	ld	s3,8(sp)
    800032a2:	6145                	addi	sp,sp,48
    800032a4:	8082                	ret
    virtio_disk_rw(b, 0);
    800032a6:	4581                	li	a1,0
    800032a8:	8526                	mv	a0,s1
    800032aa:	00003097          	auipc	ra,0x3
    800032ae:	f0c080e7          	jalr	-244(ra) # 800061b6 <virtio_disk_rw>
    b->valid = 1;
    800032b2:	4785                	li	a5,1
    800032b4:	c09c                	sw	a5,0(s1)
  return b;
    800032b6:	b7c5                	j	80003296 <bread+0xd0>

00000000800032b8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	1000                	addi	s0,sp,32
    800032c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c4:	0541                	addi	a0,a0,16
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	466080e7          	jalr	1126(ra) # 8000472c <holdingsleep>
    800032ce:	cd01                	beqz	a0,800032e6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032d0:	4585                	li	a1,1
    800032d2:	8526                	mv	a0,s1
    800032d4:	00003097          	auipc	ra,0x3
    800032d8:	ee2080e7          	jalr	-286(ra) # 800061b6 <virtio_disk_rw>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret
    panic("bwrite");
    800032e6:	00005517          	auipc	a0,0x5
    800032ea:	2fa50513          	addi	a0,a0,762 # 800085e0 <syscalls+0xf0>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	250080e7          	jalr	592(ra) # 8000053e <panic>

00000000800032f6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	e04a                	sd	s2,0(sp)
    80003300:	1000                	addi	s0,sp,32
    80003302:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003304:	01050913          	addi	s2,a0,16
    80003308:	854a                	mv	a0,s2
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	422080e7          	jalr	1058(ra) # 8000472c <holdingsleep>
    80003312:	c92d                	beqz	a0,80003384 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	3d2080e7          	jalr	978(ra) # 800046e8 <releasesleep>

  acquire(&bcache.lock);
    8000331e:	00015517          	auipc	a0,0x15
    80003322:	80250513          	addi	a0,a0,-2046 # 80017b20 <bcache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	8be080e7          	jalr	-1858(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000332e:	40bc                	lw	a5,64(s1)
    80003330:	37fd                	addiw	a5,a5,-1
    80003332:	0007871b          	sext.w	a4,a5
    80003336:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003338:	eb05                	bnez	a4,80003368 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000333a:	68bc                	ld	a5,80(s1)
    8000333c:	64b8                	ld	a4,72(s1)
    8000333e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003340:	64bc                	ld	a5,72(s1)
    80003342:	68b8                	ld	a4,80(s1)
    80003344:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003346:	0001c797          	auipc	a5,0x1c
    8000334a:	7da78793          	addi	a5,a5,2010 # 8001fb20 <bcache+0x8000>
    8000334e:	2b87b703          	ld	a4,696(a5)
    80003352:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003354:	0001d717          	auipc	a4,0x1d
    80003358:	a3470713          	addi	a4,a4,-1484 # 8001fd88 <bcache+0x8268>
    8000335c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000335e:	2b87b703          	ld	a4,696(a5)
    80003362:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003364:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003368:	00014517          	auipc	a0,0x14
    8000336c:	7b850513          	addi	a0,a0,1976 # 80017b20 <bcache>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	928080e7          	jalr	-1752(ra) # 80000c98 <release>
}
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	64a2                	ld	s1,8(sp)
    8000337e:	6902                	ld	s2,0(sp)
    80003380:	6105                	addi	sp,sp,32
    80003382:	8082                	ret
    panic("brelse");
    80003384:	00005517          	auipc	a0,0x5
    80003388:	26450513          	addi	a0,a0,612 # 800085e8 <syscalls+0xf8>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>

0000000080003394 <bpin>:

void
bpin(struct buf *b) {
    80003394:	1101                	addi	sp,sp,-32
    80003396:	ec06                	sd	ra,24(sp)
    80003398:	e822                	sd	s0,16(sp)
    8000339a:	e426                	sd	s1,8(sp)
    8000339c:	1000                	addi	s0,sp,32
    8000339e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033a0:	00014517          	auipc	a0,0x14
    800033a4:	78050513          	addi	a0,a0,1920 # 80017b20 <bcache>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	83c080e7          	jalr	-1988(ra) # 80000be4 <acquire>
  b->refcnt++;
    800033b0:	40bc                	lw	a5,64(s1)
    800033b2:	2785                	addiw	a5,a5,1
    800033b4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b6:	00014517          	auipc	a0,0x14
    800033ba:	76a50513          	addi	a0,a0,1898 # 80017b20 <bcache>
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	8da080e7          	jalr	-1830(ra) # 80000c98 <release>
}
    800033c6:	60e2                	ld	ra,24(sp)
    800033c8:	6442                	ld	s0,16(sp)
    800033ca:	64a2                	ld	s1,8(sp)
    800033cc:	6105                	addi	sp,sp,32
    800033ce:	8082                	ret

00000000800033d0 <bunpin>:

void
bunpin(struct buf *b) {
    800033d0:	1101                	addi	sp,sp,-32
    800033d2:	ec06                	sd	ra,24(sp)
    800033d4:	e822                	sd	s0,16(sp)
    800033d6:	e426                	sd	s1,8(sp)
    800033d8:	1000                	addi	s0,sp,32
    800033da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033dc:	00014517          	auipc	a0,0x14
    800033e0:	74450513          	addi	a0,a0,1860 # 80017b20 <bcache>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	800080e7          	jalr	-2048(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033ec:	40bc                	lw	a5,64(s1)
    800033ee:	37fd                	addiw	a5,a5,-1
    800033f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033f2:	00014517          	auipc	a0,0x14
    800033f6:	72e50513          	addi	a0,a0,1838 # 80017b20 <bcache>
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
}
    80003402:	60e2                	ld	ra,24(sp)
    80003404:	6442                	ld	s0,16(sp)
    80003406:	64a2                	ld	s1,8(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret

000000008000340c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	e426                	sd	s1,8(sp)
    80003414:	e04a                	sd	s2,0(sp)
    80003416:	1000                	addi	s0,sp,32
    80003418:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000341a:	00d5d59b          	srliw	a1,a1,0xd
    8000341e:	0001d797          	auipc	a5,0x1d
    80003422:	dde7a783          	lw	a5,-546(a5) # 800201fc <sb+0x1c>
    80003426:	9dbd                	addw	a1,a1,a5
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	d9e080e7          	jalr	-610(ra) # 800031c6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003430:	0074f713          	andi	a4,s1,7
    80003434:	4785                	li	a5,1
    80003436:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000343a:	14ce                	slli	s1,s1,0x33
    8000343c:	90d9                	srli	s1,s1,0x36
    8000343e:	00950733          	add	a4,a0,s1
    80003442:	05874703          	lbu	a4,88(a4)
    80003446:	00e7f6b3          	and	a3,a5,a4
    8000344a:	c69d                	beqz	a3,80003478 <bfree+0x6c>
    8000344c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000344e:	94aa                	add	s1,s1,a0
    80003450:	fff7c793          	not	a5,a5
    80003454:	8ff9                	and	a5,a5,a4
    80003456:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	118080e7          	jalr	280(ra) # 80004572 <log_write>
  brelse(bp);
    80003462:	854a                	mv	a0,s2
    80003464:	00000097          	auipc	ra,0x0
    80003468:	e92080e7          	jalr	-366(ra) # 800032f6 <brelse>
}
    8000346c:	60e2                	ld	ra,24(sp)
    8000346e:	6442                	ld	s0,16(sp)
    80003470:	64a2                	ld	s1,8(sp)
    80003472:	6902                	ld	s2,0(sp)
    80003474:	6105                	addi	sp,sp,32
    80003476:	8082                	ret
    panic("freeing free block");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	17850513          	addi	a0,a0,376 # 800085f0 <syscalls+0x100>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0be080e7          	jalr	190(ra) # 8000053e <panic>

0000000080003488 <balloc>:
{
    80003488:	711d                	addi	sp,sp,-96
    8000348a:	ec86                	sd	ra,88(sp)
    8000348c:	e8a2                	sd	s0,80(sp)
    8000348e:	e4a6                	sd	s1,72(sp)
    80003490:	e0ca                	sd	s2,64(sp)
    80003492:	fc4e                	sd	s3,56(sp)
    80003494:	f852                	sd	s4,48(sp)
    80003496:	f456                	sd	s5,40(sp)
    80003498:	f05a                	sd	s6,32(sp)
    8000349a:	ec5e                	sd	s7,24(sp)
    8000349c:	e862                	sd	s8,16(sp)
    8000349e:	e466                	sd	s9,8(sp)
    800034a0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034a2:	0001d797          	auipc	a5,0x1d
    800034a6:	d427a783          	lw	a5,-702(a5) # 800201e4 <sb+0x4>
    800034aa:	cbd1                	beqz	a5,8000353e <balloc+0xb6>
    800034ac:	8baa                	mv	s7,a0
    800034ae:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034b0:	0001db17          	auipc	s6,0x1d
    800034b4:	d30b0b13          	addi	s6,s6,-720 # 800201e0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034ba:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034bc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034be:	6c89                	lui	s9,0x2
    800034c0:	a831                	j	800034dc <balloc+0x54>
    brelse(bp);
    800034c2:	854a                	mv	a0,s2
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	e32080e7          	jalr	-462(ra) # 800032f6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034cc:	015c87bb          	addw	a5,s9,s5
    800034d0:	00078a9b          	sext.w	s5,a5
    800034d4:	004b2703          	lw	a4,4(s6)
    800034d8:	06eaf363          	bgeu	s5,a4,8000353e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034dc:	41fad79b          	sraiw	a5,s5,0x1f
    800034e0:	0137d79b          	srliw	a5,a5,0x13
    800034e4:	015787bb          	addw	a5,a5,s5
    800034e8:	40d7d79b          	sraiw	a5,a5,0xd
    800034ec:	01cb2583          	lw	a1,28(s6)
    800034f0:	9dbd                	addw	a1,a1,a5
    800034f2:	855e                	mv	a0,s7
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	cd2080e7          	jalr	-814(ra) # 800031c6 <bread>
    800034fc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fe:	004b2503          	lw	a0,4(s6)
    80003502:	000a849b          	sext.w	s1,s5
    80003506:	8662                	mv	a2,s8
    80003508:	faa4fde3          	bgeu	s1,a0,800034c2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000350c:	41f6579b          	sraiw	a5,a2,0x1f
    80003510:	01d7d69b          	srliw	a3,a5,0x1d
    80003514:	00c6873b          	addw	a4,a3,a2
    80003518:	00777793          	andi	a5,a4,7
    8000351c:	9f95                	subw	a5,a5,a3
    8000351e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003522:	4037571b          	sraiw	a4,a4,0x3
    80003526:	00e906b3          	add	a3,s2,a4
    8000352a:	0586c683          	lbu	a3,88(a3)
    8000352e:	00d7f5b3          	and	a1,a5,a3
    80003532:	cd91                	beqz	a1,8000354e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003534:	2605                	addiw	a2,a2,1
    80003536:	2485                	addiw	s1,s1,1
    80003538:	fd4618e3          	bne	a2,s4,80003508 <balloc+0x80>
    8000353c:	b759                	j	800034c2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000353e:	00005517          	auipc	a0,0x5
    80003542:	0ca50513          	addi	a0,a0,202 # 80008608 <syscalls+0x118>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	ff8080e7          	jalr	-8(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000354e:	974a                	add	a4,a4,s2
    80003550:	8fd5                	or	a5,a5,a3
    80003552:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	00001097          	auipc	ra,0x1
    8000355c:	01a080e7          	jalr	26(ra) # 80004572 <log_write>
        brelse(bp);
    80003560:	854a                	mv	a0,s2
    80003562:	00000097          	auipc	ra,0x0
    80003566:	d94080e7          	jalr	-620(ra) # 800032f6 <brelse>
  bp = bread(dev, bno);
    8000356a:	85a6                	mv	a1,s1
    8000356c:	855e                	mv	a0,s7
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	c58080e7          	jalr	-936(ra) # 800031c6 <bread>
    80003576:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003578:	40000613          	li	a2,1024
    8000357c:	4581                	li	a1,0
    8000357e:	05850513          	addi	a0,a0,88
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	75e080e7          	jalr	1886(ra) # 80000ce0 <memset>
  log_write(bp);
    8000358a:	854a                	mv	a0,s2
    8000358c:	00001097          	auipc	ra,0x1
    80003590:	fe6080e7          	jalr	-26(ra) # 80004572 <log_write>
  brelse(bp);
    80003594:	854a                	mv	a0,s2
    80003596:	00000097          	auipc	ra,0x0
    8000359a:	d60080e7          	jalr	-672(ra) # 800032f6 <brelse>
}
    8000359e:	8526                	mv	a0,s1
    800035a0:	60e6                	ld	ra,88(sp)
    800035a2:	6446                	ld	s0,80(sp)
    800035a4:	64a6                	ld	s1,72(sp)
    800035a6:	6906                	ld	s2,64(sp)
    800035a8:	79e2                	ld	s3,56(sp)
    800035aa:	7a42                	ld	s4,48(sp)
    800035ac:	7aa2                	ld	s5,40(sp)
    800035ae:	7b02                	ld	s6,32(sp)
    800035b0:	6be2                	ld	s7,24(sp)
    800035b2:	6c42                	ld	s8,16(sp)
    800035b4:	6ca2                	ld	s9,8(sp)
    800035b6:	6125                	addi	sp,sp,96
    800035b8:	8082                	ret

00000000800035ba <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	e052                	sd	s4,0(sp)
    800035c8:	1800                	addi	s0,sp,48
    800035ca:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035cc:	47ad                	li	a5,11
    800035ce:	04b7fe63          	bgeu	a5,a1,8000362a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035d2:	ff45849b          	addiw	s1,a1,-12
    800035d6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035da:	0ff00793          	li	a5,255
    800035de:	0ae7e363          	bltu	a5,a4,80003684 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035e2:	08052583          	lw	a1,128(a0)
    800035e6:	c5ad                	beqz	a1,80003650 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035e8:	00092503          	lw	a0,0(s2)
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	bda080e7          	jalr	-1062(ra) # 800031c6 <bread>
    800035f4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035f6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035fa:	02049593          	slli	a1,s1,0x20
    800035fe:	9181                	srli	a1,a1,0x20
    80003600:	058a                	slli	a1,a1,0x2
    80003602:	00b784b3          	add	s1,a5,a1
    80003606:	0004a983          	lw	s3,0(s1)
    8000360a:	04098d63          	beqz	s3,80003664 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000360e:	8552                	mv	a0,s4
    80003610:	00000097          	auipc	ra,0x0
    80003614:	ce6080e7          	jalr	-794(ra) # 800032f6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003618:	854e                	mv	a0,s3
    8000361a:	70a2                	ld	ra,40(sp)
    8000361c:	7402                	ld	s0,32(sp)
    8000361e:	64e2                	ld	s1,24(sp)
    80003620:	6942                	ld	s2,16(sp)
    80003622:	69a2                	ld	s3,8(sp)
    80003624:	6a02                	ld	s4,0(sp)
    80003626:	6145                	addi	sp,sp,48
    80003628:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000362a:	02059493          	slli	s1,a1,0x20
    8000362e:	9081                	srli	s1,s1,0x20
    80003630:	048a                	slli	s1,s1,0x2
    80003632:	94aa                	add	s1,s1,a0
    80003634:	0504a983          	lw	s3,80(s1)
    80003638:	fe0990e3          	bnez	s3,80003618 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000363c:	4108                	lw	a0,0(a0)
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	e4a080e7          	jalr	-438(ra) # 80003488 <balloc>
    80003646:	0005099b          	sext.w	s3,a0
    8000364a:	0534a823          	sw	s3,80(s1)
    8000364e:	b7e9                	j	80003618 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003650:	4108                	lw	a0,0(a0)
    80003652:	00000097          	auipc	ra,0x0
    80003656:	e36080e7          	jalr	-458(ra) # 80003488 <balloc>
    8000365a:	0005059b          	sext.w	a1,a0
    8000365e:	08b92023          	sw	a1,128(s2)
    80003662:	b759                	j	800035e8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003664:	00092503          	lw	a0,0(s2)
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	e20080e7          	jalr	-480(ra) # 80003488 <balloc>
    80003670:	0005099b          	sext.w	s3,a0
    80003674:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003678:	8552                	mv	a0,s4
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	ef8080e7          	jalr	-264(ra) # 80004572 <log_write>
    80003682:	b771                	j	8000360e <bmap+0x54>
  panic("bmap: out of range");
    80003684:	00005517          	auipc	a0,0x5
    80003688:	f9c50513          	addi	a0,a0,-100 # 80008620 <syscalls+0x130>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>

0000000080003694 <iget>:
{
    80003694:	7179                	addi	sp,sp,-48
    80003696:	f406                	sd	ra,40(sp)
    80003698:	f022                	sd	s0,32(sp)
    8000369a:	ec26                	sd	s1,24(sp)
    8000369c:	e84a                	sd	s2,16(sp)
    8000369e:	e44e                	sd	s3,8(sp)
    800036a0:	e052                	sd	s4,0(sp)
    800036a2:	1800                	addi	s0,sp,48
    800036a4:	89aa                	mv	s3,a0
    800036a6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036a8:	0001d517          	auipc	a0,0x1d
    800036ac:	b5850513          	addi	a0,a0,-1192 # 80020200 <itable>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	534080e7          	jalr	1332(ra) # 80000be4 <acquire>
  empty = 0;
    800036b8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ba:	0001d497          	auipc	s1,0x1d
    800036be:	b5e48493          	addi	s1,s1,-1186 # 80020218 <itable+0x18>
    800036c2:	0001e697          	auipc	a3,0x1e
    800036c6:	5e668693          	addi	a3,a3,1510 # 80021ca8 <log>
    800036ca:	a039                	j	800036d8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036cc:	02090b63          	beqz	s2,80003702 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036d0:	08848493          	addi	s1,s1,136
    800036d4:	02d48a63          	beq	s1,a3,80003708 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036d8:	449c                	lw	a5,8(s1)
    800036da:	fef059e3          	blez	a5,800036cc <iget+0x38>
    800036de:	4098                	lw	a4,0(s1)
    800036e0:	ff3716e3          	bne	a4,s3,800036cc <iget+0x38>
    800036e4:	40d8                	lw	a4,4(s1)
    800036e6:	ff4713e3          	bne	a4,s4,800036cc <iget+0x38>
      ip->ref++;
    800036ea:	2785                	addiw	a5,a5,1
    800036ec:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036ee:	0001d517          	auipc	a0,0x1d
    800036f2:	b1250513          	addi	a0,a0,-1262 # 80020200 <itable>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	5a2080e7          	jalr	1442(ra) # 80000c98 <release>
      return ip;
    800036fe:	8926                	mv	s2,s1
    80003700:	a03d                	j	8000372e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003702:	f7f9                	bnez	a5,800036d0 <iget+0x3c>
    80003704:	8926                	mv	s2,s1
    80003706:	b7e9                	j	800036d0 <iget+0x3c>
  if(empty == 0)
    80003708:	02090c63          	beqz	s2,80003740 <iget+0xac>
  ip->dev = dev;
    8000370c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003710:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003714:	4785                	li	a5,1
    80003716:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000371a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000371e:	0001d517          	auipc	a0,0x1d
    80003722:	ae250513          	addi	a0,a0,-1310 # 80020200 <itable>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	572080e7          	jalr	1394(ra) # 80000c98 <release>
}
    8000372e:	854a                	mv	a0,s2
    80003730:	70a2                	ld	ra,40(sp)
    80003732:	7402                	ld	s0,32(sp)
    80003734:	64e2                	ld	s1,24(sp)
    80003736:	6942                	ld	s2,16(sp)
    80003738:	69a2                	ld	s3,8(sp)
    8000373a:	6a02                	ld	s4,0(sp)
    8000373c:	6145                	addi	sp,sp,48
    8000373e:	8082                	ret
    panic("iget: no inodes");
    80003740:	00005517          	auipc	a0,0x5
    80003744:	ef850513          	addi	a0,a0,-264 # 80008638 <syscalls+0x148>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	df6080e7          	jalr	-522(ra) # 8000053e <panic>

0000000080003750 <fsinit>:
fsinit(int dev) {
    80003750:	7179                	addi	sp,sp,-48
    80003752:	f406                	sd	ra,40(sp)
    80003754:	f022                	sd	s0,32(sp)
    80003756:	ec26                	sd	s1,24(sp)
    80003758:	e84a                	sd	s2,16(sp)
    8000375a:	e44e                	sd	s3,8(sp)
    8000375c:	1800                	addi	s0,sp,48
    8000375e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003760:	4585                	li	a1,1
    80003762:	00000097          	auipc	ra,0x0
    80003766:	a64080e7          	jalr	-1436(ra) # 800031c6 <bread>
    8000376a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000376c:	0001d997          	auipc	s3,0x1d
    80003770:	a7498993          	addi	s3,s3,-1420 # 800201e0 <sb>
    80003774:	02000613          	li	a2,32
    80003778:	05850593          	addi	a1,a0,88
    8000377c:	854e                	mv	a0,s3
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	5c2080e7          	jalr	1474(ra) # 80000d40 <memmove>
  brelse(bp);
    80003786:	8526                	mv	a0,s1
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	b6e080e7          	jalr	-1170(ra) # 800032f6 <brelse>
  if(sb.magic != FSMAGIC)
    80003790:	0009a703          	lw	a4,0(s3)
    80003794:	102037b7          	lui	a5,0x10203
    80003798:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000379c:	02f71263          	bne	a4,a5,800037c0 <fsinit+0x70>
  initlog(dev, &sb);
    800037a0:	0001d597          	auipc	a1,0x1d
    800037a4:	a4058593          	addi	a1,a1,-1472 # 800201e0 <sb>
    800037a8:	854a                	mv	a0,s2
    800037aa:	00001097          	auipc	ra,0x1
    800037ae:	b4c080e7          	jalr	-1204(ra) # 800042f6 <initlog>
}
    800037b2:	70a2                	ld	ra,40(sp)
    800037b4:	7402                	ld	s0,32(sp)
    800037b6:	64e2                	ld	s1,24(sp)
    800037b8:	6942                	ld	s2,16(sp)
    800037ba:	69a2                	ld	s3,8(sp)
    800037bc:	6145                	addi	sp,sp,48
    800037be:	8082                	ret
    panic("invalid file system");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	e8850513          	addi	a0,a0,-376 # 80008648 <syscalls+0x158>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d76080e7          	jalr	-650(ra) # 8000053e <panic>

00000000800037d0 <iinit>:
{
    800037d0:	7179                	addi	sp,sp,-48
    800037d2:	f406                	sd	ra,40(sp)
    800037d4:	f022                	sd	s0,32(sp)
    800037d6:	ec26                	sd	s1,24(sp)
    800037d8:	e84a                	sd	s2,16(sp)
    800037da:	e44e                	sd	s3,8(sp)
    800037dc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037de:	00005597          	auipc	a1,0x5
    800037e2:	e8258593          	addi	a1,a1,-382 # 80008660 <syscalls+0x170>
    800037e6:	0001d517          	auipc	a0,0x1d
    800037ea:	a1a50513          	addi	a0,a0,-1510 # 80020200 <itable>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	366080e7          	jalr	870(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037f6:	0001d497          	auipc	s1,0x1d
    800037fa:	a3248493          	addi	s1,s1,-1486 # 80020228 <itable+0x28>
    800037fe:	0001e997          	auipc	s3,0x1e
    80003802:	4ba98993          	addi	s3,s3,1210 # 80021cb8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003806:	00005917          	auipc	s2,0x5
    8000380a:	e6290913          	addi	s2,s2,-414 # 80008668 <syscalls+0x178>
    8000380e:	85ca                	mv	a1,s2
    80003810:	8526                	mv	a0,s1
    80003812:	00001097          	auipc	ra,0x1
    80003816:	e46080e7          	jalr	-442(ra) # 80004658 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000381a:	08848493          	addi	s1,s1,136
    8000381e:	ff3498e3          	bne	s1,s3,8000380e <iinit+0x3e>
}
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6145                	addi	sp,sp,48
    8000382e:	8082                	ret

0000000080003830 <ialloc>:
{
    80003830:	715d                	addi	sp,sp,-80
    80003832:	e486                	sd	ra,72(sp)
    80003834:	e0a2                	sd	s0,64(sp)
    80003836:	fc26                	sd	s1,56(sp)
    80003838:	f84a                	sd	s2,48(sp)
    8000383a:	f44e                	sd	s3,40(sp)
    8000383c:	f052                	sd	s4,32(sp)
    8000383e:	ec56                	sd	s5,24(sp)
    80003840:	e85a                	sd	s6,16(sp)
    80003842:	e45e                	sd	s7,8(sp)
    80003844:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003846:	0001d717          	auipc	a4,0x1d
    8000384a:	9a672703          	lw	a4,-1626(a4) # 800201ec <sb+0xc>
    8000384e:	4785                	li	a5,1
    80003850:	04e7fa63          	bgeu	a5,a4,800038a4 <ialloc+0x74>
    80003854:	8aaa                	mv	s5,a0
    80003856:	8bae                	mv	s7,a1
    80003858:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000385a:	0001da17          	auipc	s4,0x1d
    8000385e:	986a0a13          	addi	s4,s4,-1658 # 800201e0 <sb>
    80003862:	00048b1b          	sext.w	s6,s1
    80003866:	0044d593          	srli	a1,s1,0x4
    8000386a:	018a2783          	lw	a5,24(s4)
    8000386e:	9dbd                	addw	a1,a1,a5
    80003870:	8556                	mv	a0,s5
    80003872:	00000097          	auipc	ra,0x0
    80003876:	954080e7          	jalr	-1708(ra) # 800031c6 <bread>
    8000387a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000387c:	05850993          	addi	s3,a0,88
    80003880:	00f4f793          	andi	a5,s1,15
    80003884:	079a                	slli	a5,a5,0x6
    80003886:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003888:	00099783          	lh	a5,0(s3)
    8000388c:	c785                	beqz	a5,800038b4 <ialloc+0x84>
    brelse(bp);
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	a68080e7          	jalr	-1432(ra) # 800032f6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003896:	0485                	addi	s1,s1,1
    80003898:	00ca2703          	lw	a4,12(s4)
    8000389c:	0004879b          	sext.w	a5,s1
    800038a0:	fce7e1e3          	bltu	a5,a4,80003862 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038a4:	00005517          	auipc	a0,0x5
    800038a8:	dcc50513          	addi	a0,a0,-564 # 80008670 <syscalls+0x180>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	c92080e7          	jalr	-878(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800038b4:	04000613          	li	a2,64
    800038b8:	4581                	li	a1,0
    800038ba:	854e                	mv	a0,s3
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	424080e7          	jalr	1060(ra) # 80000ce0 <memset>
      dip->type = type;
    800038c4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038c8:	854a                	mv	a0,s2
    800038ca:	00001097          	auipc	ra,0x1
    800038ce:	ca8080e7          	jalr	-856(ra) # 80004572 <log_write>
      brelse(bp);
    800038d2:	854a                	mv	a0,s2
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	a22080e7          	jalr	-1502(ra) # 800032f6 <brelse>
      return iget(dev, inum);
    800038dc:	85da                	mv	a1,s6
    800038de:	8556                	mv	a0,s5
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	db4080e7          	jalr	-588(ra) # 80003694 <iget>
}
    800038e8:	60a6                	ld	ra,72(sp)
    800038ea:	6406                	ld	s0,64(sp)
    800038ec:	74e2                	ld	s1,56(sp)
    800038ee:	7942                	ld	s2,48(sp)
    800038f0:	79a2                	ld	s3,40(sp)
    800038f2:	7a02                	ld	s4,32(sp)
    800038f4:	6ae2                	ld	s5,24(sp)
    800038f6:	6b42                	ld	s6,16(sp)
    800038f8:	6ba2                	ld	s7,8(sp)
    800038fa:	6161                	addi	sp,sp,80
    800038fc:	8082                	ret

00000000800038fe <iupdate>:
{
    800038fe:	1101                	addi	sp,sp,-32
    80003900:	ec06                	sd	ra,24(sp)
    80003902:	e822                	sd	s0,16(sp)
    80003904:	e426                	sd	s1,8(sp)
    80003906:	e04a                	sd	s2,0(sp)
    80003908:	1000                	addi	s0,sp,32
    8000390a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000390c:	415c                	lw	a5,4(a0)
    8000390e:	0047d79b          	srliw	a5,a5,0x4
    80003912:	0001d597          	auipc	a1,0x1d
    80003916:	8e65a583          	lw	a1,-1818(a1) # 800201f8 <sb+0x18>
    8000391a:	9dbd                	addw	a1,a1,a5
    8000391c:	4108                	lw	a0,0(a0)
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	8a8080e7          	jalr	-1880(ra) # 800031c6 <bread>
    80003926:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003928:	05850793          	addi	a5,a0,88
    8000392c:	40c8                	lw	a0,4(s1)
    8000392e:	893d                	andi	a0,a0,15
    80003930:	051a                	slli	a0,a0,0x6
    80003932:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003934:	04449703          	lh	a4,68(s1)
    80003938:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000393c:	04649703          	lh	a4,70(s1)
    80003940:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003944:	04849703          	lh	a4,72(s1)
    80003948:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000394c:	04a49703          	lh	a4,74(s1)
    80003950:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003954:	44f8                	lw	a4,76(s1)
    80003956:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003958:	03400613          	li	a2,52
    8000395c:	05048593          	addi	a1,s1,80
    80003960:	0531                	addi	a0,a0,12
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	3de080e7          	jalr	990(ra) # 80000d40 <memmove>
  log_write(bp);
    8000396a:	854a                	mv	a0,s2
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	c06080e7          	jalr	-1018(ra) # 80004572 <log_write>
  brelse(bp);
    80003974:	854a                	mv	a0,s2
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	980080e7          	jalr	-1664(ra) # 800032f6 <brelse>
}
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6902                	ld	s2,0(sp)
    80003986:	6105                	addi	sp,sp,32
    80003988:	8082                	ret

000000008000398a <idup>:
{
    8000398a:	1101                	addi	sp,sp,-32
    8000398c:	ec06                	sd	ra,24(sp)
    8000398e:	e822                	sd	s0,16(sp)
    80003990:	e426                	sd	s1,8(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003996:	0001d517          	auipc	a0,0x1d
    8000399a:	86a50513          	addi	a0,a0,-1942 # 80020200 <itable>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	246080e7          	jalr	582(ra) # 80000be4 <acquire>
  ip->ref++;
    800039a6:	449c                	lw	a5,8(s1)
    800039a8:	2785                	addiw	a5,a5,1
    800039aa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ac:	0001d517          	auipc	a0,0x1d
    800039b0:	85450513          	addi	a0,a0,-1964 # 80020200 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
}
    800039bc:	8526                	mv	a0,s1
    800039be:	60e2                	ld	ra,24(sp)
    800039c0:	6442                	ld	s0,16(sp)
    800039c2:	64a2                	ld	s1,8(sp)
    800039c4:	6105                	addi	sp,sp,32
    800039c6:	8082                	ret

00000000800039c8 <ilock>:
{
    800039c8:	1101                	addi	sp,sp,-32
    800039ca:	ec06                	sd	ra,24(sp)
    800039cc:	e822                	sd	s0,16(sp)
    800039ce:	e426                	sd	s1,8(sp)
    800039d0:	e04a                	sd	s2,0(sp)
    800039d2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039d4:	c115                	beqz	a0,800039f8 <ilock+0x30>
    800039d6:	84aa                	mv	s1,a0
    800039d8:	451c                	lw	a5,8(a0)
    800039da:	00f05f63          	blez	a5,800039f8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039de:	0541                	addi	a0,a0,16
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	cb2080e7          	jalr	-846(ra) # 80004692 <acquiresleep>
  if(ip->valid == 0){
    800039e8:	40bc                	lw	a5,64(s1)
    800039ea:	cf99                	beqz	a5,80003a08 <ilock+0x40>
}
    800039ec:	60e2                	ld	ra,24(sp)
    800039ee:	6442                	ld	s0,16(sp)
    800039f0:	64a2                	ld	s1,8(sp)
    800039f2:	6902                	ld	s2,0(sp)
    800039f4:	6105                	addi	sp,sp,32
    800039f6:	8082                	ret
    panic("ilock");
    800039f8:	00005517          	auipc	a0,0x5
    800039fc:	c9050513          	addi	a0,a0,-880 # 80008688 <syscalls+0x198>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	b3e080e7          	jalr	-1218(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a08:	40dc                	lw	a5,4(s1)
    80003a0a:	0047d79b          	srliw	a5,a5,0x4
    80003a0e:	0001c597          	auipc	a1,0x1c
    80003a12:	7ea5a583          	lw	a1,2026(a1) # 800201f8 <sb+0x18>
    80003a16:	9dbd                	addw	a1,a1,a5
    80003a18:	4088                	lw	a0,0(s1)
    80003a1a:	fffff097          	auipc	ra,0xfffff
    80003a1e:	7ac080e7          	jalr	1964(ra) # 800031c6 <bread>
    80003a22:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a24:	05850593          	addi	a1,a0,88
    80003a28:	40dc                	lw	a5,4(s1)
    80003a2a:	8bbd                	andi	a5,a5,15
    80003a2c:	079a                	slli	a5,a5,0x6
    80003a2e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a30:	00059783          	lh	a5,0(a1)
    80003a34:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a38:	00259783          	lh	a5,2(a1)
    80003a3c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a40:	00459783          	lh	a5,4(a1)
    80003a44:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a48:	00659783          	lh	a5,6(a1)
    80003a4c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a50:	459c                	lw	a5,8(a1)
    80003a52:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a54:	03400613          	li	a2,52
    80003a58:	05b1                	addi	a1,a1,12
    80003a5a:	05048513          	addi	a0,s1,80
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	2e2080e7          	jalr	738(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a66:	854a                	mv	a0,s2
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	88e080e7          	jalr	-1906(ra) # 800032f6 <brelse>
    ip->valid = 1;
    80003a70:	4785                	li	a5,1
    80003a72:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a74:	04449783          	lh	a5,68(s1)
    80003a78:	fbb5                	bnez	a5,800039ec <ilock+0x24>
      panic("ilock: no type");
    80003a7a:	00005517          	auipc	a0,0x5
    80003a7e:	c1650513          	addi	a0,a0,-1002 # 80008690 <syscalls+0x1a0>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	abc080e7          	jalr	-1348(ra) # 8000053e <panic>

0000000080003a8a <iunlock>:
{
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	e04a                	sd	s2,0(sp)
    80003a94:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a96:	c905                	beqz	a0,80003ac6 <iunlock+0x3c>
    80003a98:	84aa                	mv	s1,a0
    80003a9a:	01050913          	addi	s2,a0,16
    80003a9e:	854a                	mv	a0,s2
    80003aa0:	00001097          	auipc	ra,0x1
    80003aa4:	c8c080e7          	jalr	-884(ra) # 8000472c <holdingsleep>
    80003aa8:	cd19                	beqz	a0,80003ac6 <iunlock+0x3c>
    80003aaa:	449c                	lw	a5,8(s1)
    80003aac:	00f05d63          	blez	a5,80003ac6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	00001097          	auipc	ra,0x1
    80003ab6:	c36080e7          	jalr	-970(ra) # 800046e8 <releasesleep>
}
    80003aba:	60e2                	ld	ra,24(sp)
    80003abc:	6442                	ld	s0,16(sp)
    80003abe:	64a2                	ld	s1,8(sp)
    80003ac0:	6902                	ld	s2,0(sp)
    80003ac2:	6105                	addi	sp,sp,32
    80003ac4:	8082                	ret
    panic("iunlock");
    80003ac6:	00005517          	auipc	a0,0x5
    80003aca:	bda50513          	addi	a0,a0,-1062 # 800086a0 <syscalls+0x1b0>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>

0000000080003ad6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ad6:	7179                	addi	sp,sp,-48
    80003ad8:	f406                	sd	ra,40(sp)
    80003ada:	f022                	sd	s0,32(sp)
    80003adc:	ec26                	sd	s1,24(sp)
    80003ade:	e84a                	sd	s2,16(sp)
    80003ae0:	e44e                	sd	s3,8(sp)
    80003ae2:	e052                	sd	s4,0(sp)
    80003ae4:	1800                	addi	s0,sp,48
    80003ae6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ae8:	05050493          	addi	s1,a0,80
    80003aec:	08050913          	addi	s2,a0,128
    80003af0:	a021                	j	80003af8 <itrunc+0x22>
    80003af2:	0491                	addi	s1,s1,4
    80003af4:	01248d63          	beq	s1,s2,80003b0e <itrunc+0x38>
    if(ip->addrs[i]){
    80003af8:	408c                	lw	a1,0(s1)
    80003afa:	dde5                	beqz	a1,80003af2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003afc:	0009a503          	lw	a0,0(s3)
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	90c080e7          	jalr	-1780(ra) # 8000340c <bfree>
      ip->addrs[i] = 0;
    80003b08:	0004a023          	sw	zero,0(s1)
    80003b0c:	b7dd                	j	80003af2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b0e:	0809a583          	lw	a1,128(s3)
    80003b12:	e185                	bnez	a1,80003b32 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b14:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b18:	854e                	mv	a0,s3
    80003b1a:	00000097          	auipc	ra,0x0
    80003b1e:	de4080e7          	jalr	-540(ra) # 800038fe <iupdate>
}
    80003b22:	70a2                	ld	ra,40(sp)
    80003b24:	7402                	ld	s0,32(sp)
    80003b26:	64e2                	ld	s1,24(sp)
    80003b28:	6942                	ld	s2,16(sp)
    80003b2a:	69a2                	ld	s3,8(sp)
    80003b2c:	6a02                	ld	s4,0(sp)
    80003b2e:	6145                	addi	sp,sp,48
    80003b30:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b32:	0009a503          	lw	a0,0(s3)
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	690080e7          	jalr	1680(ra) # 800031c6 <bread>
    80003b3e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b40:	05850493          	addi	s1,a0,88
    80003b44:	45850913          	addi	s2,a0,1112
    80003b48:	a811                	j	80003b5c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b4a:	0009a503          	lw	a0,0(s3)
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	8be080e7          	jalr	-1858(ra) # 8000340c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b56:	0491                	addi	s1,s1,4
    80003b58:	01248563          	beq	s1,s2,80003b62 <itrunc+0x8c>
      if(a[j])
    80003b5c:	408c                	lw	a1,0(s1)
    80003b5e:	dde5                	beqz	a1,80003b56 <itrunc+0x80>
    80003b60:	b7ed                	j	80003b4a <itrunc+0x74>
    brelse(bp);
    80003b62:	8552                	mv	a0,s4
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	792080e7          	jalr	1938(ra) # 800032f6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b6c:	0809a583          	lw	a1,128(s3)
    80003b70:	0009a503          	lw	a0,0(s3)
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	898080e7          	jalr	-1896(ra) # 8000340c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b7c:	0809a023          	sw	zero,128(s3)
    80003b80:	bf51                	j	80003b14 <itrunc+0x3e>

0000000080003b82 <iput>:
{
    80003b82:	1101                	addi	sp,sp,-32
    80003b84:	ec06                	sd	ra,24(sp)
    80003b86:	e822                	sd	s0,16(sp)
    80003b88:	e426                	sd	s1,8(sp)
    80003b8a:	e04a                	sd	s2,0(sp)
    80003b8c:	1000                	addi	s0,sp,32
    80003b8e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b90:	0001c517          	auipc	a0,0x1c
    80003b94:	67050513          	addi	a0,a0,1648 # 80020200 <itable>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	04c080e7          	jalr	76(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ba0:	4498                	lw	a4,8(s1)
    80003ba2:	4785                	li	a5,1
    80003ba4:	02f70363          	beq	a4,a5,80003bca <iput+0x48>
  ip->ref--;
    80003ba8:	449c                	lw	a5,8(s1)
    80003baa:	37fd                	addiw	a5,a5,-1
    80003bac:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bae:	0001c517          	auipc	a0,0x1c
    80003bb2:	65250513          	addi	a0,a0,1618 # 80020200 <itable>
    80003bb6:	ffffd097          	auipc	ra,0xffffd
    80003bba:	0e2080e7          	jalr	226(ra) # 80000c98 <release>
}
    80003bbe:	60e2                	ld	ra,24(sp)
    80003bc0:	6442                	ld	s0,16(sp)
    80003bc2:	64a2                	ld	s1,8(sp)
    80003bc4:	6902                	ld	s2,0(sp)
    80003bc6:	6105                	addi	sp,sp,32
    80003bc8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bca:	40bc                	lw	a5,64(s1)
    80003bcc:	dff1                	beqz	a5,80003ba8 <iput+0x26>
    80003bce:	04a49783          	lh	a5,74(s1)
    80003bd2:	fbf9                	bnez	a5,80003ba8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bd4:	01048913          	addi	s2,s1,16
    80003bd8:	854a                	mv	a0,s2
    80003bda:	00001097          	auipc	ra,0x1
    80003bde:	ab8080e7          	jalr	-1352(ra) # 80004692 <acquiresleep>
    release(&itable.lock);
    80003be2:	0001c517          	auipc	a0,0x1c
    80003be6:	61e50513          	addi	a0,a0,1566 # 80020200 <itable>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	0ae080e7          	jalr	174(ra) # 80000c98 <release>
    itrunc(ip);
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	ee2080e7          	jalr	-286(ra) # 80003ad6 <itrunc>
    ip->type = 0;
    80003bfc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c00:	8526                	mv	a0,s1
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	cfc080e7          	jalr	-772(ra) # 800038fe <iupdate>
    ip->valid = 0;
    80003c0a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c0e:	854a                	mv	a0,s2
    80003c10:	00001097          	auipc	ra,0x1
    80003c14:	ad8080e7          	jalr	-1320(ra) # 800046e8 <releasesleep>
    acquire(&itable.lock);
    80003c18:	0001c517          	auipc	a0,0x1c
    80003c1c:	5e850513          	addi	a0,a0,1512 # 80020200 <itable>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	fc4080e7          	jalr	-60(ra) # 80000be4 <acquire>
    80003c28:	b741                	j	80003ba8 <iput+0x26>

0000000080003c2a <iunlockput>:
{
    80003c2a:	1101                	addi	sp,sp,-32
    80003c2c:	ec06                	sd	ra,24(sp)
    80003c2e:	e822                	sd	s0,16(sp)
    80003c30:	e426                	sd	s1,8(sp)
    80003c32:	1000                	addi	s0,sp,32
    80003c34:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	e54080e7          	jalr	-428(ra) # 80003a8a <iunlock>
  iput(ip);
    80003c3e:	8526                	mv	a0,s1
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	f42080e7          	jalr	-190(ra) # 80003b82 <iput>
}
    80003c48:	60e2                	ld	ra,24(sp)
    80003c4a:	6442                	ld	s0,16(sp)
    80003c4c:	64a2                	ld	s1,8(sp)
    80003c4e:	6105                	addi	sp,sp,32
    80003c50:	8082                	ret

0000000080003c52 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c52:	1141                	addi	sp,sp,-16
    80003c54:	e422                	sd	s0,8(sp)
    80003c56:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c58:	411c                	lw	a5,0(a0)
    80003c5a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c5c:	415c                	lw	a5,4(a0)
    80003c5e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c60:	04451783          	lh	a5,68(a0)
    80003c64:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c68:	04a51783          	lh	a5,74(a0)
    80003c6c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c70:	04c56783          	lwu	a5,76(a0)
    80003c74:	e99c                	sd	a5,16(a1)
}
    80003c76:	6422                	ld	s0,8(sp)
    80003c78:	0141                	addi	sp,sp,16
    80003c7a:	8082                	ret

0000000080003c7c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7c:	457c                	lw	a5,76(a0)
    80003c7e:	0ed7e963          	bltu	a5,a3,80003d70 <readi+0xf4>
{
    80003c82:	7159                	addi	sp,sp,-112
    80003c84:	f486                	sd	ra,104(sp)
    80003c86:	f0a2                	sd	s0,96(sp)
    80003c88:	eca6                	sd	s1,88(sp)
    80003c8a:	e8ca                	sd	s2,80(sp)
    80003c8c:	e4ce                	sd	s3,72(sp)
    80003c8e:	e0d2                	sd	s4,64(sp)
    80003c90:	fc56                	sd	s5,56(sp)
    80003c92:	f85a                	sd	s6,48(sp)
    80003c94:	f45e                	sd	s7,40(sp)
    80003c96:	f062                	sd	s8,32(sp)
    80003c98:	ec66                	sd	s9,24(sp)
    80003c9a:	e86a                	sd	s10,16(sp)
    80003c9c:	e46e                	sd	s11,8(sp)
    80003c9e:	1880                	addi	s0,sp,112
    80003ca0:	8baa                	mv	s7,a0
    80003ca2:	8c2e                	mv	s8,a1
    80003ca4:	8ab2                	mv	s5,a2
    80003ca6:	84b6                	mv	s1,a3
    80003ca8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003caa:	9f35                	addw	a4,a4,a3
    return 0;
    80003cac:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cae:	0ad76063          	bltu	a4,a3,80003d4e <readi+0xd2>
  if(off + n > ip->size)
    80003cb2:	00e7f463          	bgeu	a5,a4,80003cba <readi+0x3e>
    n = ip->size - off;
    80003cb6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cba:	0a0b0963          	beqz	s6,80003d6c <readi+0xf0>
    80003cbe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cc4:	5cfd                	li	s9,-1
    80003cc6:	a82d                	j	80003d00 <readi+0x84>
    80003cc8:	020a1d93          	slli	s11,s4,0x20
    80003ccc:	020ddd93          	srli	s11,s11,0x20
    80003cd0:	05890613          	addi	a2,s2,88
    80003cd4:	86ee                	mv	a3,s11
    80003cd6:	963a                	add	a2,a2,a4
    80003cd8:	85d6                	mv	a1,s5
    80003cda:	8562                	mv	a0,s8
    80003cdc:	ffffe097          	auipc	ra,0xffffe
    80003ce0:	312080e7          	jalr	786(ra) # 80001fee <either_copyout>
    80003ce4:	05950d63          	beq	a0,s9,80003d3e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ce8:	854a                	mv	a0,s2
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	60c080e7          	jalr	1548(ra) # 800032f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf2:	013a09bb          	addw	s3,s4,s3
    80003cf6:	009a04bb          	addw	s1,s4,s1
    80003cfa:	9aee                	add	s5,s5,s11
    80003cfc:	0569f763          	bgeu	s3,s6,80003d4a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d00:	000ba903          	lw	s2,0(s7)
    80003d04:	00a4d59b          	srliw	a1,s1,0xa
    80003d08:	855e                	mv	a0,s7
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	8b0080e7          	jalr	-1872(ra) # 800035ba <bmap>
    80003d12:	0005059b          	sext.w	a1,a0
    80003d16:	854a                	mv	a0,s2
    80003d18:	fffff097          	auipc	ra,0xfffff
    80003d1c:	4ae080e7          	jalr	1198(ra) # 800031c6 <bread>
    80003d20:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d22:	3ff4f713          	andi	a4,s1,1023
    80003d26:	40ed07bb          	subw	a5,s10,a4
    80003d2a:	413b06bb          	subw	a3,s6,s3
    80003d2e:	8a3e                	mv	s4,a5
    80003d30:	2781                	sext.w	a5,a5
    80003d32:	0006861b          	sext.w	a2,a3
    80003d36:	f8f679e3          	bgeu	a2,a5,80003cc8 <readi+0x4c>
    80003d3a:	8a36                	mv	s4,a3
    80003d3c:	b771                	j	80003cc8 <readi+0x4c>
      brelse(bp);
    80003d3e:	854a                	mv	a0,s2
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	5b6080e7          	jalr	1462(ra) # 800032f6 <brelse>
      tot = -1;
    80003d48:	59fd                	li	s3,-1
  }
  return tot;
    80003d4a:	0009851b          	sext.w	a0,s3
}
    80003d4e:	70a6                	ld	ra,104(sp)
    80003d50:	7406                	ld	s0,96(sp)
    80003d52:	64e6                	ld	s1,88(sp)
    80003d54:	6946                	ld	s2,80(sp)
    80003d56:	69a6                	ld	s3,72(sp)
    80003d58:	6a06                	ld	s4,64(sp)
    80003d5a:	7ae2                	ld	s5,56(sp)
    80003d5c:	7b42                	ld	s6,48(sp)
    80003d5e:	7ba2                	ld	s7,40(sp)
    80003d60:	7c02                	ld	s8,32(sp)
    80003d62:	6ce2                	ld	s9,24(sp)
    80003d64:	6d42                	ld	s10,16(sp)
    80003d66:	6da2                	ld	s11,8(sp)
    80003d68:	6165                	addi	sp,sp,112
    80003d6a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d6c:	89da                	mv	s3,s6
    80003d6e:	bff1                	j	80003d4a <readi+0xce>
    return 0;
    80003d70:	4501                	li	a0,0
}
    80003d72:	8082                	ret

0000000080003d74 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d74:	457c                	lw	a5,76(a0)
    80003d76:	10d7e863          	bltu	a5,a3,80003e86 <writei+0x112>
{
    80003d7a:	7159                	addi	sp,sp,-112
    80003d7c:	f486                	sd	ra,104(sp)
    80003d7e:	f0a2                	sd	s0,96(sp)
    80003d80:	eca6                	sd	s1,88(sp)
    80003d82:	e8ca                	sd	s2,80(sp)
    80003d84:	e4ce                	sd	s3,72(sp)
    80003d86:	e0d2                	sd	s4,64(sp)
    80003d88:	fc56                	sd	s5,56(sp)
    80003d8a:	f85a                	sd	s6,48(sp)
    80003d8c:	f45e                	sd	s7,40(sp)
    80003d8e:	f062                	sd	s8,32(sp)
    80003d90:	ec66                	sd	s9,24(sp)
    80003d92:	e86a                	sd	s10,16(sp)
    80003d94:	e46e                	sd	s11,8(sp)
    80003d96:	1880                	addi	s0,sp,112
    80003d98:	8b2a                	mv	s6,a0
    80003d9a:	8c2e                	mv	s8,a1
    80003d9c:	8ab2                	mv	s5,a2
    80003d9e:	8936                	mv	s2,a3
    80003da0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003da2:	00e687bb          	addw	a5,a3,a4
    80003da6:	0ed7e263          	bltu	a5,a3,80003e8a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003daa:	00043737          	lui	a4,0x43
    80003dae:	0ef76063          	bltu	a4,a5,80003e8e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db2:	0c0b8863          	beqz	s7,80003e82 <writei+0x10e>
    80003db6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dbc:	5cfd                	li	s9,-1
    80003dbe:	a091                	j	80003e02 <writei+0x8e>
    80003dc0:	02099d93          	slli	s11,s3,0x20
    80003dc4:	020ddd93          	srli	s11,s11,0x20
    80003dc8:	05848513          	addi	a0,s1,88
    80003dcc:	86ee                	mv	a3,s11
    80003dce:	8656                	mv	a2,s5
    80003dd0:	85e2                	mv	a1,s8
    80003dd2:	953a                	add	a0,a0,a4
    80003dd4:	ffffe097          	auipc	ra,0xffffe
    80003dd8:	270080e7          	jalr	624(ra) # 80002044 <either_copyin>
    80003ddc:	07950263          	beq	a0,s9,80003e40 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003de0:	8526                	mv	a0,s1
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	790080e7          	jalr	1936(ra) # 80004572 <log_write>
    brelse(bp);
    80003dea:	8526                	mv	a0,s1
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	50a080e7          	jalr	1290(ra) # 800032f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df4:	01498a3b          	addw	s4,s3,s4
    80003df8:	0129893b          	addw	s2,s3,s2
    80003dfc:	9aee                	add	s5,s5,s11
    80003dfe:	057a7663          	bgeu	s4,s7,80003e4a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e02:	000b2483          	lw	s1,0(s6)
    80003e06:	00a9559b          	srliw	a1,s2,0xa
    80003e0a:	855a                	mv	a0,s6
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	7ae080e7          	jalr	1966(ra) # 800035ba <bmap>
    80003e14:	0005059b          	sext.w	a1,a0
    80003e18:	8526                	mv	a0,s1
    80003e1a:	fffff097          	auipc	ra,0xfffff
    80003e1e:	3ac080e7          	jalr	940(ra) # 800031c6 <bread>
    80003e22:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e24:	3ff97713          	andi	a4,s2,1023
    80003e28:	40ed07bb          	subw	a5,s10,a4
    80003e2c:	414b86bb          	subw	a3,s7,s4
    80003e30:	89be                	mv	s3,a5
    80003e32:	2781                	sext.w	a5,a5
    80003e34:	0006861b          	sext.w	a2,a3
    80003e38:	f8f674e3          	bgeu	a2,a5,80003dc0 <writei+0x4c>
    80003e3c:	89b6                	mv	s3,a3
    80003e3e:	b749                	j	80003dc0 <writei+0x4c>
      brelse(bp);
    80003e40:	8526                	mv	a0,s1
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	4b4080e7          	jalr	1204(ra) # 800032f6 <brelse>
  }

  if(off > ip->size)
    80003e4a:	04cb2783          	lw	a5,76(s6)
    80003e4e:	0127f463          	bgeu	a5,s2,80003e56 <writei+0xe2>
    ip->size = off;
    80003e52:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e56:	855a                	mv	a0,s6
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	aa6080e7          	jalr	-1370(ra) # 800038fe <iupdate>

  return tot;
    80003e60:	000a051b          	sext.w	a0,s4
}
    80003e64:	70a6                	ld	ra,104(sp)
    80003e66:	7406                	ld	s0,96(sp)
    80003e68:	64e6                	ld	s1,88(sp)
    80003e6a:	6946                	ld	s2,80(sp)
    80003e6c:	69a6                	ld	s3,72(sp)
    80003e6e:	6a06                	ld	s4,64(sp)
    80003e70:	7ae2                	ld	s5,56(sp)
    80003e72:	7b42                	ld	s6,48(sp)
    80003e74:	7ba2                	ld	s7,40(sp)
    80003e76:	7c02                	ld	s8,32(sp)
    80003e78:	6ce2                	ld	s9,24(sp)
    80003e7a:	6d42                	ld	s10,16(sp)
    80003e7c:	6da2                	ld	s11,8(sp)
    80003e7e:	6165                	addi	sp,sp,112
    80003e80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e82:	8a5e                	mv	s4,s7
    80003e84:	bfc9                	j	80003e56 <writei+0xe2>
    return -1;
    80003e86:	557d                	li	a0,-1
}
    80003e88:	8082                	ret
    return -1;
    80003e8a:	557d                	li	a0,-1
    80003e8c:	bfe1                	j	80003e64 <writei+0xf0>
    return -1;
    80003e8e:	557d                	li	a0,-1
    80003e90:	bfd1                	j	80003e64 <writei+0xf0>

0000000080003e92 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e92:	1141                	addi	sp,sp,-16
    80003e94:	e406                	sd	ra,8(sp)
    80003e96:	e022                	sd	s0,0(sp)
    80003e98:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e9a:	4639                	li	a2,14
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	f1c080e7          	jalr	-228(ra) # 80000db8 <strncmp>
}
    80003ea4:	60a2                	ld	ra,8(sp)
    80003ea6:	6402                	ld	s0,0(sp)
    80003ea8:	0141                	addi	sp,sp,16
    80003eaa:	8082                	ret

0000000080003eac <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eac:	7139                	addi	sp,sp,-64
    80003eae:	fc06                	sd	ra,56(sp)
    80003eb0:	f822                	sd	s0,48(sp)
    80003eb2:	f426                	sd	s1,40(sp)
    80003eb4:	f04a                	sd	s2,32(sp)
    80003eb6:	ec4e                	sd	s3,24(sp)
    80003eb8:	e852                	sd	s4,16(sp)
    80003eba:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ebc:	04451703          	lh	a4,68(a0)
    80003ec0:	4785                	li	a5,1
    80003ec2:	00f71a63          	bne	a4,a5,80003ed6 <dirlookup+0x2a>
    80003ec6:	892a                	mv	s2,a0
    80003ec8:	89ae                	mv	s3,a1
    80003eca:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ecc:	457c                	lw	a5,76(a0)
    80003ece:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ed0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed2:	e79d                	bnez	a5,80003f00 <dirlookup+0x54>
    80003ed4:	a8a5                	j	80003f4c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ed6:	00004517          	auipc	a0,0x4
    80003eda:	7d250513          	addi	a0,a0,2002 # 800086a8 <syscalls+0x1b8>
    80003ede:	ffffc097          	auipc	ra,0xffffc
    80003ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ee6:	00004517          	auipc	a0,0x4
    80003eea:	7da50513          	addi	a0,a0,2010 # 800086c0 <syscalls+0x1d0>
    80003eee:	ffffc097          	auipc	ra,0xffffc
    80003ef2:	650080e7          	jalr	1616(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef6:	24c1                	addiw	s1,s1,16
    80003ef8:	04c92783          	lw	a5,76(s2)
    80003efc:	04f4f763          	bgeu	s1,a5,80003f4a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f00:	4741                	li	a4,16
    80003f02:	86a6                	mv	a3,s1
    80003f04:	fc040613          	addi	a2,s0,-64
    80003f08:	4581                	li	a1,0
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	d70080e7          	jalr	-656(ra) # 80003c7c <readi>
    80003f14:	47c1                	li	a5,16
    80003f16:	fcf518e3          	bne	a0,a5,80003ee6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f1a:	fc045783          	lhu	a5,-64(s0)
    80003f1e:	dfe1                	beqz	a5,80003ef6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f20:	fc240593          	addi	a1,s0,-62
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	f6c080e7          	jalr	-148(ra) # 80003e92 <namecmp>
    80003f2e:	f561                	bnez	a0,80003ef6 <dirlookup+0x4a>
      if(poff)
    80003f30:	000a0463          	beqz	s4,80003f38 <dirlookup+0x8c>
        *poff = off;
    80003f34:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f38:	fc045583          	lhu	a1,-64(s0)
    80003f3c:	00092503          	lw	a0,0(s2)
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	754080e7          	jalr	1876(ra) # 80003694 <iget>
    80003f48:	a011                	j	80003f4c <dirlookup+0xa0>
  return 0;
    80003f4a:	4501                	li	a0,0
}
    80003f4c:	70e2                	ld	ra,56(sp)
    80003f4e:	7442                	ld	s0,48(sp)
    80003f50:	74a2                	ld	s1,40(sp)
    80003f52:	7902                	ld	s2,32(sp)
    80003f54:	69e2                	ld	s3,24(sp)
    80003f56:	6a42                	ld	s4,16(sp)
    80003f58:	6121                	addi	sp,sp,64
    80003f5a:	8082                	ret

0000000080003f5c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f5c:	711d                	addi	sp,sp,-96
    80003f5e:	ec86                	sd	ra,88(sp)
    80003f60:	e8a2                	sd	s0,80(sp)
    80003f62:	e4a6                	sd	s1,72(sp)
    80003f64:	e0ca                	sd	s2,64(sp)
    80003f66:	fc4e                	sd	s3,56(sp)
    80003f68:	f852                	sd	s4,48(sp)
    80003f6a:	f456                	sd	s5,40(sp)
    80003f6c:	f05a                	sd	s6,32(sp)
    80003f6e:	ec5e                	sd	s7,24(sp)
    80003f70:	e862                	sd	s8,16(sp)
    80003f72:	e466                	sd	s9,8(sp)
    80003f74:	1080                	addi	s0,sp,96
    80003f76:	84aa                	mv	s1,a0
    80003f78:	8b2e                	mv	s6,a1
    80003f7a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f7c:	00054703          	lbu	a4,0(a0)
    80003f80:	02f00793          	li	a5,47
    80003f84:	02f70363          	beq	a4,a5,80003faa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f88:	ffffe097          	auipc	ra,0xffffe
    80003f8c:	a38080e7          	jalr	-1480(ra) # 800019c0 <myproc>
    80003f90:	17853503          	ld	a0,376(a0)
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	9f6080e7          	jalr	-1546(ra) # 8000398a <idup>
    80003f9c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f9e:	02f00913          	li	s2,47
  len = path - s;
    80003fa2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003fa4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fa6:	4c05                	li	s8,1
    80003fa8:	a865                	j	80004060 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003faa:	4585                	li	a1,1
    80003fac:	4505                	li	a0,1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	6e6080e7          	jalr	1766(ra) # 80003694 <iget>
    80003fb6:	89aa                	mv	s3,a0
    80003fb8:	b7dd                	j	80003f9e <namex+0x42>
      iunlockput(ip);
    80003fba:	854e                	mv	a0,s3
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	c6e080e7          	jalr	-914(ra) # 80003c2a <iunlockput>
      return 0;
    80003fc4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fc6:	854e                	mv	a0,s3
    80003fc8:	60e6                	ld	ra,88(sp)
    80003fca:	6446                	ld	s0,80(sp)
    80003fcc:	64a6                	ld	s1,72(sp)
    80003fce:	6906                	ld	s2,64(sp)
    80003fd0:	79e2                	ld	s3,56(sp)
    80003fd2:	7a42                	ld	s4,48(sp)
    80003fd4:	7aa2                	ld	s5,40(sp)
    80003fd6:	7b02                	ld	s6,32(sp)
    80003fd8:	6be2                	ld	s7,24(sp)
    80003fda:	6c42                	ld	s8,16(sp)
    80003fdc:	6ca2                	ld	s9,8(sp)
    80003fde:	6125                	addi	sp,sp,96
    80003fe0:	8082                	ret
      iunlock(ip);
    80003fe2:	854e                	mv	a0,s3
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	aa6080e7          	jalr	-1370(ra) # 80003a8a <iunlock>
      return ip;
    80003fec:	bfe9                	j	80003fc6 <namex+0x6a>
      iunlockput(ip);
    80003fee:	854e                	mv	a0,s3
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	c3a080e7          	jalr	-966(ra) # 80003c2a <iunlockput>
      return 0;
    80003ff8:	89d2                	mv	s3,s4
    80003ffa:	b7f1                	j	80003fc6 <namex+0x6a>
  len = path - s;
    80003ffc:	40b48633          	sub	a2,s1,a1
    80004000:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004004:	094cd463          	bge	s9,s4,8000408c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004008:	4639                	li	a2,14
    8000400a:	8556                	mv	a0,s5
    8000400c:	ffffd097          	auipc	ra,0xffffd
    80004010:	d34080e7          	jalr	-716(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004014:	0004c783          	lbu	a5,0(s1)
    80004018:	01279763          	bne	a5,s2,80004026 <namex+0xca>
    path++;
    8000401c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401e:	0004c783          	lbu	a5,0(s1)
    80004022:	ff278de3          	beq	a5,s2,8000401c <namex+0xc0>
    ilock(ip);
    80004026:	854e                	mv	a0,s3
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	9a0080e7          	jalr	-1632(ra) # 800039c8 <ilock>
    if(ip->type != T_DIR){
    80004030:	04499783          	lh	a5,68(s3)
    80004034:	f98793e3          	bne	a5,s8,80003fba <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004038:	000b0563          	beqz	s6,80004042 <namex+0xe6>
    8000403c:	0004c783          	lbu	a5,0(s1)
    80004040:	d3cd                	beqz	a5,80003fe2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004042:	865e                	mv	a2,s7
    80004044:	85d6                	mv	a1,s5
    80004046:	854e                	mv	a0,s3
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	e64080e7          	jalr	-412(ra) # 80003eac <dirlookup>
    80004050:	8a2a                	mv	s4,a0
    80004052:	dd51                	beqz	a0,80003fee <namex+0x92>
    iunlockput(ip);
    80004054:	854e                	mv	a0,s3
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	bd4080e7          	jalr	-1068(ra) # 80003c2a <iunlockput>
    ip = next;
    8000405e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004060:	0004c783          	lbu	a5,0(s1)
    80004064:	05279763          	bne	a5,s2,800040b2 <namex+0x156>
    path++;
    80004068:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000406a:	0004c783          	lbu	a5,0(s1)
    8000406e:	ff278de3          	beq	a5,s2,80004068 <namex+0x10c>
  if(*path == 0)
    80004072:	c79d                	beqz	a5,800040a0 <namex+0x144>
    path++;
    80004074:	85a6                	mv	a1,s1
  len = path - s;
    80004076:	8a5e                	mv	s4,s7
    80004078:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000407a:	01278963          	beq	a5,s2,8000408c <namex+0x130>
    8000407e:	dfbd                	beqz	a5,80003ffc <namex+0xa0>
    path++;
    80004080:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004082:	0004c783          	lbu	a5,0(s1)
    80004086:	ff279ce3          	bne	a5,s2,8000407e <namex+0x122>
    8000408a:	bf8d                	j	80003ffc <namex+0xa0>
    memmove(name, s, len);
    8000408c:	2601                	sext.w	a2,a2
    8000408e:	8556                	mv	a0,s5
    80004090:	ffffd097          	auipc	ra,0xffffd
    80004094:	cb0080e7          	jalr	-848(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004098:	9a56                	add	s4,s4,s5
    8000409a:	000a0023          	sb	zero,0(s4)
    8000409e:	bf9d                	j	80004014 <namex+0xb8>
  if(nameiparent){
    800040a0:	f20b03e3          	beqz	s6,80003fc6 <namex+0x6a>
    iput(ip);
    800040a4:	854e                	mv	a0,s3
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	adc080e7          	jalr	-1316(ra) # 80003b82 <iput>
    return 0;
    800040ae:	4981                	li	s3,0
    800040b0:	bf19                	j	80003fc6 <namex+0x6a>
  if(*path == 0)
    800040b2:	d7fd                	beqz	a5,800040a0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040b4:	0004c783          	lbu	a5,0(s1)
    800040b8:	85a6                	mv	a1,s1
    800040ba:	b7d1                	j	8000407e <namex+0x122>

00000000800040bc <dirlink>:
{
    800040bc:	7139                	addi	sp,sp,-64
    800040be:	fc06                	sd	ra,56(sp)
    800040c0:	f822                	sd	s0,48(sp)
    800040c2:	f426                	sd	s1,40(sp)
    800040c4:	f04a                	sd	s2,32(sp)
    800040c6:	ec4e                	sd	s3,24(sp)
    800040c8:	e852                	sd	s4,16(sp)
    800040ca:	0080                	addi	s0,sp,64
    800040cc:	892a                	mv	s2,a0
    800040ce:	8a2e                	mv	s4,a1
    800040d0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040d2:	4601                	li	a2,0
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	dd8080e7          	jalr	-552(ra) # 80003eac <dirlookup>
    800040dc:	e93d                	bnez	a0,80004152 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040de:	04c92483          	lw	s1,76(s2)
    800040e2:	c49d                	beqz	s1,80004110 <dirlink+0x54>
    800040e4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e6:	4741                	li	a4,16
    800040e8:	86a6                	mv	a3,s1
    800040ea:	fc040613          	addi	a2,s0,-64
    800040ee:	4581                	li	a1,0
    800040f0:	854a                	mv	a0,s2
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	b8a080e7          	jalr	-1142(ra) # 80003c7c <readi>
    800040fa:	47c1                	li	a5,16
    800040fc:	06f51163          	bne	a0,a5,8000415e <dirlink+0xa2>
    if(de.inum == 0)
    80004100:	fc045783          	lhu	a5,-64(s0)
    80004104:	c791                	beqz	a5,80004110 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004106:	24c1                	addiw	s1,s1,16
    80004108:	04c92783          	lw	a5,76(s2)
    8000410c:	fcf4ede3          	bltu	s1,a5,800040e6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004110:	4639                	li	a2,14
    80004112:	85d2                	mv	a1,s4
    80004114:	fc240513          	addi	a0,s0,-62
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	cdc080e7          	jalr	-804(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004120:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004124:	4741                	li	a4,16
    80004126:	86a6                	mv	a3,s1
    80004128:	fc040613          	addi	a2,s0,-64
    8000412c:	4581                	li	a1,0
    8000412e:	854a                	mv	a0,s2
    80004130:	00000097          	auipc	ra,0x0
    80004134:	c44080e7          	jalr	-956(ra) # 80003d74 <writei>
    80004138:	872a                	mv	a4,a0
    8000413a:	47c1                	li	a5,16
  return 0;
    8000413c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000413e:	02f71863          	bne	a4,a5,8000416e <dirlink+0xb2>
}
    80004142:	70e2                	ld	ra,56(sp)
    80004144:	7442                	ld	s0,48(sp)
    80004146:	74a2                	ld	s1,40(sp)
    80004148:	7902                	ld	s2,32(sp)
    8000414a:	69e2                	ld	s3,24(sp)
    8000414c:	6a42                	ld	s4,16(sp)
    8000414e:	6121                	addi	sp,sp,64
    80004150:	8082                	ret
    iput(ip);
    80004152:	00000097          	auipc	ra,0x0
    80004156:	a30080e7          	jalr	-1488(ra) # 80003b82 <iput>
    return -1;
    8000415a:	557d                	li	a0,-1
    8000415c:	b7dd                	j	80004142 <dirlink+0x86>
      panic("dirlink read");
    8000415e:	00004517          	auipc	a0,0x4
    80004162:	57250513          	addi	a0,a0,1394 # 800086d0 <syscalls+0x1e0>
    80004166:	ffffc097          	auipc	ra,0xffffc
    8000416a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>
    panic("dirlink");
    8000416e:	00004517          	auipc	a0,0x4
    80004172:	67250513          	addi	a0,a0,1650 # 800087e0 <syscalls+0x2f0>
    80004176:	ffffc097          	auipc	ra,0xffffc
    8000417a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>

000000008000417e <namei>:

struct inode*
namei(char *path)
{
    8000417e:	1101                	addi	sp,sp,-32
    80004180:	ec06                	sd	ra,24(sp)
    80004182:	e822                	sd	s0,16(sp)
    80004184:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004186:	fe040613          	addi	a2,s0,-32
    8000418a:	4581                	li	a1,0
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	dd0080e7          	jalr	-560(ra) # 80003f5c <namex>
}
    80004194:	60e2                	ld	ra,24(sp)
    80004196:	6442                	ld	s0,16(sp)
    80004198:	6105                	addi	sp,sp,32
    8000419a:	8082                	ret

000000008000419c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000419c:	1141                	addi	sp,sp,-16
    8000419e:	e406                	sd	ra,8(sp)
    800041a0:	e022                	sd	s0,0(sp)
    800041a2:	0800                	addi	s0,sp,16
    800041a4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041a6:	4585                	li	a1,1
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	db4080e7          	jalr	-588(ra) # 80003f5c <namex>
}
    800041b0:	60a2                	ld	ra,8(sp)
    800041b2:	6402                	ld	s0,0(sp)
    800041b4:	0141                	addi	sp,sp,16
    800041b6:	8082                	ret

00000000800041b8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041b8:	1101                	addi	sp,sp,-32
    800041ba:	ec06                	sd	ra,24(sp)
    800041bc:	e822                	sd	s0,16(sp)
    800041be:	e426                	sd	s1,8(sp)
    800041c0:	e04a                	sd	s2,0(sp)
    800041c2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041c4:	0001e917          	auipc	s2,0x1e
    800041c8:	ae490913          	addi	s2,s2,-1308 # 80021ca8 <log>
    800041cc:	01892583          	lw	a1,24(s2)
    800041d0:	02892503          	lw	a0,40(s2)
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	ff2080e7          	jalr	-14(ra) # 800031c6 <bread>
    800041dc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041de:	02c92683          	lw	a3,44(s2)
    800041e2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041e4:	02d05763          	blez	a3,80004212 <write_head+0x5a>
    800041e8:	0001e797          	auipc	a5,0x1e
    800041ec:	af078793          	addi	a5,a5,-1296 # 80021cd8 <log+0x30>
    800041f0:	05c50713          	addi	a4,a0,92
    800041f4:	36fd                	addiw	a3,a3,-1
    800041f6:	1682                	slli	a3,a3,0x20
    800041f8:	9281                	srli	a3,a3,0x20
    800041fa:	068a                	slli	a3,a3,0x2
    800041fc:	0001e617          	auipc	a2,0x1e
    80004200:	ae060613          	addi	a2,a2,-1312 # 80021cdc <log+0x34>
    80004204:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004206:	4390                	lw	a2,0(a5)
    80004208:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000420a:	0791                	addi	a5,a5,4
    8000420c:	0711                	addi	a4,a4,4
    8000420e:	fed79ce3          	bne	a5,a3,80004206 <write_head+0x4e>
  }
  bwrite(buf);
    80004212:	8526                	mv	a0,s1
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	0a4080e7          	jalr	164(ra) # 800032b8 <bwrite>
  brelse(buf);
    8000421c:	8526                	mv	a0,s1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	0d8080e7          	jalr	216(ra) # 800032f6 <brelse>
}
    80004226:	60e2                	ld	ra,24(sp)
    80004228:	6442                	ld	s0,16(sp)
    8000422a:	64a2                	ld	s1,8(sp)
    8000422c:	6902                	ld	s2,0(sp)
    8000422e:	6105                	addi	sp,sp,32
    80004230:	8082                	ret

0000000080004232 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004232:	0001e797          	auipc	a5,0x1e
    80004236:	aa27a783          	lw	a5,-1374(a5) # 80021cd4 <log+0x2c>
    8000423a:	0af05d63          	blez	a5,800042f4 <install_trans+0xc2>
{
    8000423e:	7139                	addi	sp,sp,-64
    80004240:	fc06                	sd	ra,56(sp)
    80004242:	f822                	sd	s0,48(sp)
    80004244:	f426                	sd	s1,40(sp)
    80004246:	f04a                	sd	s2,32(sp)
    80004248:	ec4e                	sd	s3,24(sp)
    8000424a:	e852                	sd	s4,16(sp)
    8000424c:	e456                	sd	s5,8(sp)
    8000424e:	e05a                	sd	s6,0(sp)
    80004250:	0080                	addi	s0,sp,64
    80004252:	8b2a                	mv	s6,a0
    80004254:	0001ea97          	auipc	s5,0x1e
    80004258:	a84a8a93          	addi	s5,s5,-1404 # 80021cd8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000425c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000425e:	0001e997          	auipc	s3,0x1e
    80004262:	a4a98993          	addi	s3,s3,-1462 # 80021ca8 <log>
    80004266:	a035                	j	80004292 <install_trans+0x60>
      bunpin(dbuf);
    80004268:	8526                	mv	a0,s1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	166080e7          	jalr	358(ra) # 800033d0 <bunpin>
    brelse(lbuf);
    80004272:	854a                	mv	a0,s2
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	082080e7          	jalr	130(ra) # 800032f6 <brelse>
    brelse(dbuf);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	078080e7          	jalr	120(ra) # 800032f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004286:	2a05                	addiw	s4,s4,1
    80004288:	0a91                	addi	s5,s5,4
    8000428a:	02c9a783          	lw	a5,44(s3)
    8000428e:	04fa5963          	bge	s4,a5,800042e0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004292:	0189a583          	lw	a1,24(s3)
    80004296:	014585bb          	addw	a1,a1,s4
    8000429a:	2585                	addiw	a1,a1,1
    8000429c:	0289a503          	lw	a0,40(s3)
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	f26080e7          	jalr	-218(ra) # 800031c6 <bread>
    800042a8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042aa:	000aa583          	lw	a1,0(s5)
    800042ae:	0289a503          	lw	a0,40(s3)
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	f14080e7          	jalr	-236(ra) # 800031c6 <bread>
    800042ba:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042bc:	40000613          	li	a2,1024
    800042c0:	05890593          	addi	a1,s2,88
    800042c4:	05850513          	addi	a0,a0,88
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	a78080e7          	jalr	-1416(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042d0:	8526                	mv	a0,s1
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	fe6080e7          	jalr	-26(ra) # 800032b8 <bwrite>
    if(recovering == 0)
    800042da:	f80b1ce3          	bnez	s6,80004272 <install_trans+0x40>
    800042de:	b769                	j	80004268 <install_trans+0x36>
}
    800042e0:	70e2                	ld	ra,56(sp)
    800042e2:	7442                	ld	s0,48(sp)
    800042e4:	74a2                	ld	s1,40(sp)
    800042e6:	7902                	ld	s2,32(sp)
    800042e8:	69e2                	ld	s3,24(sp)
    800042ea:	6a42                	ld	s4,16(sp)
    800042ec:	6aa2                	ld	s5,8(sp)
    800042ee:	6b02                	ld	s6,0(sp)
    800042f0:	6121                	addi	sp,sp,64
    800042f2:	8082                	ret
    800042f4:	8082                	ret

00000000800042f6 <initlog>:
{
    800042f6:	7179                	addi	sp,sp,-48
    800042f8:	f406                	sd	ra,40(sp)
    800042fa:	f022                	sd	s0,32(sp)
    800042fc:	ec26                	sd	s1,24(sp)
    800042fe:	e84a                	sd	s2,16(sp)
    80004300:	e44e                	sd	s3,8(sp)
    80004302:	1800                	addi	s0,sp,48
    80004304:	892a                	mv	s2,a0
    80004306:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004308:	0001e497          	auipc	s1,0x1e
    8000430c:	9a048493          	addi	s1,s1,-1632 # 80021ca8 <log>
    80004310:	00004597          	auipc	a1,0x4
    80004314:	3d058593          	addi	a1,a1,976 # 800086e0 <syscalls+0x1f0>
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffd097          	auipc	ra,0xffffd
    8000431e:	83a080e7          	jalr	-1990(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004322:	0149a583          	lw	a1,20(s3)
    80004326:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004328:	0109a783          	lw	a5,16(s3)
    8000432c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000432e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004332:	854a                	mv	a0,s2
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	e92080e7          	jalr	-366(ra) # 800031c6 <bread>
  log.lh.n = lh->n;
    8000433c:	4d3c                	lw	a5,88(a0)
    8000433e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004340:	02f05563          	blez	a5,8000436a <initlog+0x74>
    80004344:	05c50713          	addi	a4,a0,92
    80004348:	0001e697          	auipc	a3,0x1e
    8000434c:	99068693          	addi	a3,a3,-1648 # 80021cd8 <log+0x30>
    80004350:	37fd                	addiw	a5,a5,-1
    80004352:	1782                	slli	a5,a5,0x20
    80004354:	9381                	srli	a5,a5,0x20
    80004356:	078a                	slli	a5,a5,0x2
    80004358:	06050613          	addi	a2,a0,96
    8000435c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000435e:	4310                	lw	a2,0(a4)
    80004360:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004362:	0711                	addi	a4,a4,4
    80004364:	0691                	addi	a3,a3,4
    80004366:	fef71ce3          	bne	a4,a5,8000435e <initlog+0x68>
  brelse(buf);
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	f8c080e7          	jalr	-116(ra) # 800032f6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004372:	4505                	li	a0,1
    80004374:	00000097          	auipc	ra,0x0
    80004378:	ebe080e7          	jalr	-322(ra) # 80004232 <install_trans>
  log.lh.n = 0;
    8000437c:	0001e797          	auipc	a5,0x1e
    80004380:	9407ac23          	sw	zero,-1704(a5) # 80021cd4 <log+0x2c>
  write_head(); // clear the log
    80004384:	00000097          	auipc	ra,0x0
    80004388:	e34080e7          	jalr	-460(ra) # 800041b8 <write_head>
}
    8000438c:	70a2                	ld	ra,40(sp)
    8000438e:	7402                	ld	s0,32(sp)
    80004390:	64e2                	ld	s1,24(sp)
    80004392:	6942                	ld	s2,16(sp)
    80004394:	69a2                	ld	s3,8(sp)
    80004396:	6145                	addi	sp,sp,48
    80004398:	8082                	ret

000000008000439a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000439a:	1101                	addi	sp,sp,-32
    8000439c:	ec06                	sd	ra,24(sp)
    8000439e:	e822                	sd	s0,16(sp)
    800043a0:	e426                	sd	s1,8(sp)
    800043a2:	e04a                	sd	s2,0(sp)
    800043a4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043a6:	0001e517          	auipc	a0,0x1e
    800043aa:	90250513          	addi	a0,a0,-1790 # 80021ca8 <log>
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	836080e7          	jalr	-1994(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800043b6:	0001e497          	auipc	s1,0x1e
    800043ba:	8f248493          	addi	s1,s1,-1806 # 80021ca8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043be:	4979                	li	s2,30
    800043c0:	a039                	j	800043ce <begin_op+0x34>
      sleep(&log, &log.lock);
    800043c2:	85a6                	mv	a1,s1
    800043c4:	8526                	mv	a0,s1
    800043c6:	ffffe097          	auipc	ra,0xffffe
    800043ca:	03e080e7          	jalr	62(ra) # 80002404 <sleep>
    if(log.committing){
    800043ce:	50dc                	lw	a5,36(s1)
    800043d0:	fbed                	bnez	a5,800043c2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043d2:	509c                	lw	a5,32(s1)
    800043d4:	0017871b          	addiw	a4,a5,1
    800043d8:	0007069b          	sext.w	a3,a4
    800043dc:	0027179b          	slliw	a5,a4,0x2
    800043e0:	9fb9                	addw	a5,a5,a4
    800043e2:	0017979b          	slliw	a5,a5,0x1
    800043e6:	54d8                	lw	a4,44(s1)
    800043e8:	9fb9                	addw	a5,a5,a4
    800043ea:	00f95963          	bge	s2,a5,800043fc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043ee:	85a6                	mv	a1,s1
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffe097          	auipc	ra,0xffffe
    800043f6:	012080e7          	jalr	18(ra) # 80002404 <sleep>
    800043fa:	bfd1                	j	800043ce <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043fc:	0001e517          	auipc	a0,0x1e
    80004400:	8ac50513          	addi	a0,a0,-1876 # 80021ca8 <log>
    80004404:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	892080e7          	jalr	-1902(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000440e:	60e2                	ld	ra,24(sp)
    80004410:	6442                	ld	s0,16(sp)
    80004412:	64a2                	ld	s1,8(sp)
    80004414:	6902                	ld	s2,0(sp)
    80004416:	6105                	addi	sp,sp,32
    80004418:	8082                	ret

000000008000441a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000441a:	7139                	addi	sp,sp,-64
    8000441c:	fc06                	sd	ra,56(sp)
    8000441e:	f822                	sd	s0,48(sp)
    80004420:	f426                	sd	s1,40(sp)
    80004422:	f04a                	sd	s2,32(sp)
    80004424:	ec4e                	sd	s3,24(sp)
    80004426:	e852                	sd	s4,16(sp)
    80004428:	e456                	sd	s5,8(sp)
    8000442a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000442c:	0001e497          	auipc	s1,0x1e
    80004430:	87c48493          	addi	s1,s1,-1924 # 80021ca8 <log>
    80004434:	8526                	mv	a0,s1
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000443e:	509c                	lw	a5,32(s1)
    80004440:	37fd                	addiw	a5,a5,-1
    80004442:	0007891b          	sext.w	s2,a5
    80004446:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004448:	50dc                	lw	a5,36(s1)
    8000444a:	efb9                	bnez	a5,800044a8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000444c:	06091663          	bnez	s2,800044b8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004450:	0001e497          	auipc	s1,0x1e
    80004454:	85848493          	addi	s1,s1,-1960 # 80021ca8 <log>
    80004458:	4785                	li	a5,1
    8000445a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	83a080e7          	jalr	-1990(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004466:	54dc                	lw	a5,44(s1)
    80004468:	06f04763          	bgtz	a5,800044d6 <end_op+0xbc>
    acquire(&log.lock);
    8000446c:	0001e497          	auipc	s1,0x1e
    80004470:	83c48493          	addi	s1,s1,-1988 # 80021ca8 <log>
    80004474:	8526                	mv	a0,s1
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	76e080e7          	jalr	1902(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000447e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004482:	8526                	mv	a0,s1
    80004484:	ffffe097          	auipc	ra,0xffffe
    80004488:	118080e7          	jalr	280(ra) # 8000259c <wakeup>
    release(&log.lock);
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	80a080e7          	jalr	-2038(ra) # 80000c98 <release>
}
    80004496:	70e2                	ld	ra,56(sp)
    80004498:	7442                	ld	s0,48(sp)
    8000449a:	74a2                	ld	s1,40(sp)
    8000449c:	7902                	ld	s2,32(sp)
    8000449e:	69e2                	ld	s3,24(sp)
    800044a0:	6a42                	ld	s4,16(sp)
    800044a2:	6aa2                	ld	s5,8(sp)
    800044a4:	6121                	addi	sp,sp,64
    800044a6:	8082                	ret
    panic("log.committing");
    800044a8:	00004517          	auipc	a0,0x4
    800044ac:	24050513          	addi	a0,a0,576 # 800086e8 <syscalls+0x1f8>
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	08e080e7          	jalr	142(ra) # 8000053e <panic>
    wakeup(&log);
    800044b8:	0001d497          	auipc	s1,0x1d
    800044bc:	7f048493          	addi	s1,s1,2032 # 80021ca8 <log>
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffe097          	auipc	ra,0xffffe
    800044c6:	0da080e7          	jalr	218(ra) # 8000259c <wakeup>
  release(&log.lock);
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
  if(do_commit){
    800044d4:	b7c9                	j	80004496 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d6:	0001ea97          	auipc	s5,0x1e
    800044da:	802a8a93          	addi	s5,s5,-2046 # 80021cd8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044de:	0001da17          	auipc	s4,0x1d
    800044e2:	7caa0a13          	addi	s4,s4,1994 # 80021ca8 <log>
    800044e6:	018a2583          	lw	a1,24(s4)
    800044ea:	012585bb          	addw	a1,a1,s2
    800044ee:	2585                	addiw	a1,a1,1
    800044f0:	028a2503          	lw	a0,40(s4)
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	cd2080e7          	jalr	-814(ra) # 800031c6 <bread>
    800044fc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044fe:	000aa583          	lw	a1,0(s5)
    80004502:	028a2503          	lw	a0,40(s4)
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	cc0080e7          	jalr	-832(ra) # 800031c6 <bread>
    8000450e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004510:	40000613          	li	a2,1024
    80004514:	05850593          	addi	a1,a0,88
    80004518:	05848513          	addi	a0,s1,88
    8000451c:	ffffd097          	auipc	ra,0xffffd
    80004520:	824080e7          	jalr	-2012(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004524:	8526                	mv	a0,s1
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	d92080e7          	jalr	-622(ra) # 800032b8 <bwrite>
    brelse(from);
    8000452e:	854e                	mv	a0,s3
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	dc6080e7          	jalr	-570(ra) # 800032f6 <brelse>
    brelse(to);
    80004538:	8526                	mv	a0,s1
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	dbc080e7          	jalr	-580(ra) # 800032f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004542:	2905                	addiw	s2,s2,1
    80004544:	0a91                	addi	s5,s5,4
    80004546:	02ca2783          	lw	a5,44(s4)
    8000454a:	f8f94ee3          	blt	s2,a5,800044e6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	c6a080e7          	jalr	-918(ra) # 800041b8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004556:	4501                	li	a0,0
    80004558:	00000097          	auipc	ra,0x0
    8000455c:	cda080e7          	jalr	-806(ra) # 80004232 <install_trans>
    log.lh.n = 0;
    80004560:	0001d797          	auipc	a5,0x1d
    80004564:	7607aa23          	sw	zero,1908(a5) # 80021cd4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004568:	00000097          	auipc	ra,0x0
    8000456c:	c50080e7          	jalr	-944(ra) # 800041b8 <write_head>
    80004570:	bdf5                	j	8000446c <end_op+0x52>

0000000080004572 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	e04a                	sd	s2,0(sp)
    8000457c:	1000                	addi	s0,sp,32
    8000457e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004580:	0001d917          	auipc	s2,0x1d
    80004584:	72890913          	addi	s2,s2,1832 # 80021ca8 <log>
    80004588:	854a                	mv	a0,s2
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	65a080e7          	jalr	1626(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004592:	02c92603          	lw	a2,44(s2)
    80004596:	47f5                	li	a5,29
    80004598:	06c7c563          	blt	a5,a2,80004602 <log_write+0x90>
    8000459c:	0001d797          	auipc	a5,0x1d
    800045a0:	7287a783          	lw	a5,1832(a5) # 80021cc4 <log+0x1c>
    800045a4:	37fd                	addiw	a5,a5,-1
    800045a6:	04f65e63          	bge	a2,a5,80004602 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045aa:	0001d797          	auipc	a5,0x1d
    800045ae:	71e7a783          	lw	a5,1822(a5) # 80021cc8 <log+0x20>
    800045b2:	06f05063          	blez	a5,80004612 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045b6:	4781                	li	a5,0
    800045b8:	06c05563          	blez	a2,80004622 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045bc:	44cc                	lw	a1,12(s1)
    800045be:	0001d717          	auipc	a4,0x1d
    800045c2:	71a70713          	addi	a4,a4,1818 # 80021cd8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045c8:	4314                	lw	a3,0(a4)
    800045ca:	04b68c63          	beq	a3,a1,80004622 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045ce:	2785                	addiw	a5,a5,1
    800045d0:	0711                	addi	a4,a4,4
    800045d2:	fef61be3          	bne	a2,a5,800045c8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045d6:	0621                	addi	a2,a2,8
    800045d8:	060a                	slli	a2,a2,0x2
    800045da:	0001d797          	auipc	a5,0x1d
    800045de:	6ce78793          	addi	a5,a5,1742 # 80021ca8 <log>
    800045e2:	963e                	add	a2,a2,a5
    800045e4:	44dc                	lw	a5,12(s1)
    800045e6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045e8:	8526                	mv	a0,s1
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	daa080e7          	jalr	-598(ra) # 80003394 <bpin>
    log.lh.n++;
    800045f2:	0001d717          	auipc	a4,0x1d
    800045f6:	6b670713          	addi	a4,a4,1718 # 80021ca8 <log>
    800045fa:	575c                	lw	a5,44(a4)
    800045fc:	2785                	addiw	a5,a5,1
    800045fe:	d75c                	sw	a5,44(a4)
    80004600:	a835                	j	8000463c <log_write+0xca>
    panic("too big a transaction");
    80004602:	00004517          	auipc	a0,0x4
    80004606:	0f650513          	addi	a0,a0,246 # 800086f8 <syscalls+0x208>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	f34080e7          	jalr	-204(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004612:	00004517          	auipc	a0,0x4
    80004616:	0fe50513          	addi	a0,a0,254 # 80008710 <syscalls+0x220>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	f24080e7          	jalr	-220(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004622:	00878713          	addi	a4,a5,8
    80004626:	00271693          	slli	a3,a4,0x2
    8000462a:	0001d717          	auipc	a4,0x1d
    8000462e:	67e70713          	addi	a4,a4,1662 # 80021ca8 <log>
    80004632:	9736                	add	a4,a4,a3
    80004634:	44d4                	lw	a3,12(s1)
    80004636:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004638:	faf608e3          	beq	a2,a5,800045e8 <log_write+0x76>
  }
  release(&log.lock);
    8000463c:	0001d517          	auipc	a0,0x1d
    80004640:	66c50513          	addi	a0,a0,1644 # 80021ca8 <log>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	654080e7          	jalr	1620(ra) # 80000c98 <release>
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6902                	ld	s2,0(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret

0000000080004658 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004658:	1101                	addi	sp,sp,-32
    8000465a:	ec06                	sd	ra,24(sp)
    8000465c:	e822                	sd	s0,16(sp)
    8000465e:	e426                	sd	s1,8(sp)
    80004660:	e04a                	sd	s2,0(sp)
    80004662:	1000                	addi	s0,sp,32
    80004664:	84aa                	mv	s1,a0
    80004666:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004668:	00004597          	auipc	a1,0x4
    8000466c:	0c858593          	addi	a1,a1,200 # 80008730 <syscalls+0x240>
    80004670:	0521                	addi	a0,a0,8
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	4e2080e7          	jalr	1250(ra) # 80000b54 <initlock>
  lk->name = name;
    8000467a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000467e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004682:	0204a423          	sw	zero,40(s1)
}
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6902                	ld	s2,0(sp)
    8000468e:	6105                	addi	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004692:	1101                	addi	sp,sp,-32
    80004694:	ec06                	sd	ra,24(sp)
    80004696:	e822                	sd	s0,16(sp)
    80004698:	e426                	sd	s1,8(sp)
    8000469a:	e04a                	sd	s2,0(sp)
    8000469c:	1000                	addi	s0,sp,32
    8000469e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a0:	00850913          	addi	s2,a0,8
    800046a4:	854a                	mv	a0,s2
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	53e080e7          	jalr	1342(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800046ae:	409c                	lw	a5,0(s1)
    800046b0:	cb89                	beqz	a5,800046c2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046b2:	85ca                	mv	a1,s2
    800046b4:	8526                	mv	a0,s1
    800046b6:	ffffe097          	auipc	ra,0xffffe
    800046ba:	d4e080e7          	jalr	-690(ra) # 80002404 <sleep>
  while (lk->locked) {
    800046be:	409c                	lw	a5,0(s1)
    800046c0:	fbed                	bnez	a5,800046b2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046c2:	4785                	li	a5,1
    800046c4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046c6:	ffffd097          	auipc	ra,0xffffd
    800046ca:	2fa080e7          	jalr	762(ra) # 800019c0 <myproc>
    800046ce:	591c                	lw	a5,48(a0)
    800046d0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046d2:	854a                	mv	a0,s2
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
}
    800046dc:	60e2                	ld	ra,24(sp)
    800046de:	6442                	ld	s0,16(sp)
    800046e0:	64a2                	ld	s1,8(sp)
    800046e2:	6902                	ld	s2,0(sp)
    800046e4:	6105                	addi	sp,sp,32
    800046e6:	8082                	ret

00000000800046e8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046e8:	1101                	addi	sp,sp,-32
    800046ea:	ec06                	sd	ra,24(sp)
    800046ec:	e822                	sd	s0,16(sp)
    800046ee:	e426                	sd	s1,8(sp)
    800046f0:	e04a                	sd	s2,0(sp)
    800046f2:	1000                	addi	s0,sp,32
    800046f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046f6:	00850913          	addi	s2,a0,8
    800046fa:	854a                	mv	a0,s2
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	4e8080e7          	jalr	1256(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004704:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004708:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000470c:	8526                	mv	a0,s1
    8000470e:	ffffe097          	auipc	ra,0xffffe
    80004712:	e8e080e7          	jalr	-370(ra) # 8000259c <wakeup>
  release(&lk->lk);
    80004716:	854a                	mv	a0,s2
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	580080e7          	jalr	1408(ra) # 80000c98 <release>
}
    80004720:	60e2                	ld	ra,24(sp)
    80004722:	6442                	ld	s0,16(sp)
    80004724:	64a2                	ld	s1,8(sp)
    80004726:	6902                	ld	s2,0(sp)
    80004728:	6105                	addi	sp,sp,32
    8000472a:	8082                	ret

000000008000472c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000472c:	7179                	addi	sp,sp,-48
    8000472e:	f406                	sd	ra,40(sp)
    80004730:	f022                	sd	s0,32(sp)
    80004732:	ec26                	sd	s1,24(sp)
    80004734:	e84a                	sd	s2,16(sp)
    80004736:	e44e                	sd	s3,8(sp)
    80004738:	1800                	addi	s0,sp,48
    8000473a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000473c:	00850913          	addi	s2,a0,8
    80004740:	854a                	mv	a0,s2
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	4a2080e7          	jalr	1186(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000474a:	409c                	lw	a5,0(s1)
    8000474c:	ef99                	bnez	a5,8000476a <holdingsleep+0x3e>
    8000474e:	4481                	li	s1,0
  release(&lk->lk);
    80004750:	854a                	mv	a0,s2
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
  return r;
}
    8000475a:	8526                	mv	a0,s1
    8000475c:	70a2                	ld	ra,40(sp)
    8000475e:	7402                	ld	s0,32(sp)
    80004760:	64e2                	ld	s1,24(sp)
    80004762:	6942                	ld	s2,16(sp)
    80004764:	69a2                	ld	s3,8(sp)
    80004766:	6145                	addi	sp,sp,48
    80004768:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000476a:	0284a983          	lw	s3,40(s1)
    8000476e:	ffffd097          	auipc	ra,0xffffd
    80004772:	252080e7          	jalr	594(ra) # 800019c0 <myproc>
    80004776:	5904                	lw	s1,48(a0)
    80004778:	413484b3          	sub	s1,s1,s3
    8000477c:	0014b493          	seqz	s1,s1
    80004780:	bfc1                	j	80004750 <holdingsleep+0x24>

0000000080004782 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004782:	1141                	addi	sp,sp,-16
    80004784:	e406                	sd	ra,8(sp)
    80004786:	e022                	sd	s0,0(sp)
    80004788:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000478a:	00004597          	auipc	a1,0x4
    8000478e:	fb658593          	addi	a1,a1,-74 # 80008740 <syscalls+0x250>
    80004792:	0001d517          	auipc	a0,0x1d
    80004796:	65e50513          	addi	a0,a0,1630 # 80021df0 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	3ba080e7          	jalr	954(ra) # 80000b54 <initlock>
}
    800047a2:	60a2                	ld	ra,8(sp)
    800047a4:	6402                	ld	s0,0(sp)
    800047a6:	0141                	addi	sp,sp,16
    800047a8:	8082                	ret

00000000800047aa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047aa:	1101                	addi	sp,sp,-32
    800047ac:	ec06                	sd	ra,24(sp)
    800047ae:	e822                	sd	s0,16(sp)
    800047b0:	e426                	sd	s1,8(sp)
    800047b2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047b4:	0001d517          	auipc	a0,0x1d
    800047b8:	63c50513          	addi	a0,a0,1596 # 80021df0 <ftable>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047c4:	0001d497          	auipc	s1,0x1d
    800047c8:	64448493          	addi	s1,s1,1604 # 80021e08 <ftable+0x18>
    800047cc:	0001e717          	auipc	a4,0x1e
    800047d0:	5dc70713          	addi	a4,a4,1500 # 80022da8 <ftable+0xfb8>
    if(f->ref == 0){
    800047d4:	40dc                	lw	a5,4(s1)
    800047d6:	cf99                	beqz	a5,800047f4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d8:	02848493          	addi	s1,s1,40
    800047dc:	fee49ce3          	bne	s1,a4,800047d4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047e0:	0001d517          	auipc	a0,0x1d
    800047e4:	61050513          	addi	a0,a0,1552 # 80021df0 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	4b0080e7          	jalr	1200(ra) # 80000c98 <release>
  return 0;
    800047f0:	4481                	li	s1,0
    800047f2:	a819                	j	80004808 <filealloc+0x5e>
      f->ref = 1;
    800047f4:	4785                	li	a5,1
    800047f6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047f8:	0001d517          	auipc	a0,0x1d
    800047fc:	5f850513          	addi	a0,a0,1528 # 80021df0 <ftable>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	498080e7          	jalr	1176(ra) # 80000c98 <release>
}
    80004808:	8526                	mv	a0,s1
    8000480a:	60e2                	ld	ra,24(sp)
    8000480c:	6442                	ld	s0,16(sp)
    8000480e:	64a2                	ld	s1,8(sp)
    80004810:	6105                	addi	sp,sp,32
    80004812:	8082                	ret

0000000080004814 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	1000                	addi	s0,sp,32
    8000481e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004820:	0001d517          	auipc	a0,0x1d
    80004824:	5d050513          	addi	a0,a0,1488 # 80021df0 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	3bc080e7          	jalr	956(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004830:	40dc                	lw	a5,4(s1)
    80004832:	02f05263          	blez	a5,80004856 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004836:	2785                	addiw	a5,a5,1
    80004838:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000483a:	0001d517          	auipc	a0,0x1d
    8000483e:	5b650513          	addi	a0,a0,1462 # 80021df0 <ftable>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	456080e7          	jalr	1110(ra) # 80000c98 <release>
  return f;
}
    8000484a:	8526                	mv	a0,s1
    8000484c:	60e2                	ld	ra,24(sp)
    8000484e:	6442                	ld	s0,16(sp)
    80004850:	64a2                	ld	s1,8(sp)
    80004852:	6105                	addi	sp,sp,32
    80004854:	8082                	ret
    panic("filedup");
    80004856:	00004517          	auipc	a0,0x4
    8000485a:	ef250513          	addi	a0,a0,-270 # 80008748 <syscalls+0x258>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>

0000000080004866 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004866:	7139                	addi	sp,sp,-64
    80004868:	fc06                	sd	ra,56(sp)
    8000486a:	f822                	sd	s0,48(sp)
    8000486c:	f426                	sd	s1,40(sp)
    8000486e:	f04a                	sd	s2,32(sp)
    80004870:	ec4e                	sd	s3,24(sp)
    80004872:	e852                	sd	s4,16(sp)
    80004874:	e456                	sd	s5,8(sp)
    80004876:	0080                	addi	s0,sp,64
    80004878:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000487a:	0001d517          	auipc	a0,0x1d
    8000487e:	57650513          	addi	a0,a0,1398 # 80021df0 <ftable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	362080e7          	jalr	866(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000488a:	40dc                	lw	a5,4(s1)
    8000488c:	06f05163          	blez	a5,800048ee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004890:	37fd                	addiw	a5,a5,-1
    80004892:	0007871b          	sext.w	a4,a5
    80004896:	c0dc                	sw	a5,4(s1)
    80004898:	06e04363          	bgtz	a4,800048fe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000489c:	0004a903          	lw	s2,0(s1)
    800048a0:	0094ca83          	lbu	s5,9(s1)
    800048a4:	0104ba03          	ld	s4,16(s1)
    800048a8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048b0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048b4:	0001d517          	auipc	a0,0x1d
    800048b8:	53c50513          	addi	a0,a0,1340 # 80021df0 <ftable>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800048c4:	4785                	li	a5,1
    800048c6:	04f90d63          	beq	s2,a5,80004920 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048ca:	3979                	addiw	s2,s2,-2
    800048cc:	4785                	li	a5,1
    800048ce:	0527e063          	bltu	a5,s2,8000490e <fileclose+0xa8>
    begin_op();
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	ac8080e7          	jalr	-1336(ra) # 8000439a <begin_op>
    iput(ff.ip);
    800048da:	854e                	mv	a0,s3
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	2a6080e7          	jalr	678(ra) # 80003b82 <iput>
    end_op();
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	b36080e7          	jalr	-1226(ra) # 8000441a <end_op>
    800048ec:	a00d                	j	8000490e <fileclose+0xa8>
    panic("fileclose");
    800048ee:	00004517          	auipc	a0,0x4
    800048f2:	e6250513          	addi	a0,a0,-414 # 80008750 <syscalls+0x260>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	c48080e7          	jalr	-952(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048fe:	0001d517          	auipc	a0,0x1d
    80004902:	4f250513          	addi	a0,a0,1266 # 80021df0 <ftable>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	392080e7          	jalr	914(ra) # 80000c98 <release>
  }
}
    8000490e:	70e2                	ld	ra,56(sp)
    80004910:	7442                	ld	s0,48(sp)
    80004912:	74a2                	ld	s1,40(sp)
    80004914:	7902                	ld	s2,32(sp)
    80004916:	69e2                	ld	s3,24(sp)
    80004918:	6a42                	ld	s4,16(sp)
    8000491a:	6aa2                	ld	s5,8(sp)
    8000491c:	6121                	addi	sp,sp,64
    8000491e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004920:	85d6                	mv	a1,s5
    80004922:	8552                	mv	a0,s4
    80004924:	00000097          	auipc	ra,0x0
    80004928:	34c080e7          	jalr	844(ra) # 80004c70 <pipeclose>
    8000492c:	b7cd                	j	8000490e <fileclose+0xa8>

000000008000492e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000492e:	715d                	addi	sp,sp,-80
    80004930:	e486                	sd	ra,72(sp)
    80004932:	e0a2                	sd	s0,64(sp)
    80004934:	fc26                	sd	s1,56(sp)
    80004936:	f84a                	sd	s2,48(sp)
    80004938:	f44e                	sd	s3,40(sp)
    8000493a:	0880                	addi	s0,sp,80
    8000493c:	84aa                	mv	s1,a0
    8000493e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004940:	ffffd097          	auipc	ra,0xffffd
    80004944:	080080e7          	jalr	128(ra) # 800019c0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004948:	409c                	lw	a5,0(s1)
    8000494a:	37f9                	addiw	a5,a5,-2
    8000494c:	4705                	li	a4,1
    8000494e:	04f76763          	bltu	a4,a5,8000499c <filestat+0x6e>
    80004952:	892a                	mv	s2,a0
    ilock(f->ip);
    80004954:	6c88                	ld	a0,24(s1)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	072080e7          	jalr	114(ra) # 800039c8 <ilock>
    stati(f->ip, &st);
    8000495e:	fb840593          	addi	a1,s0,-72
    80004962:	6c88                	ld	a0,24(s1)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	2ee080e7          	jalr	750(ra) # 80003c52 <stati>
    iunlock(f->ip);
    8000496c:	6c88                	ld	a0,24(s1)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	11c080e7          	jalr	284(ra) # 80003a8a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004976:	46e1                	li	a3,24
    80004978:	fb840613          	addi	a2,s0,-72
    8000497c:	85ce                	mv	a1,s3
    8000497e:	07893503          	ld	a0,120(s2)
    80004982:	ffffd097          	auipc	ra,0xffffd
    80004986:	cf0080e7          	jalr	-784(ra) # 80001672 <copyout>
    8000498a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000498e:	60a6                	ld	ra,72(sp)
    80004990:	6406                	ld	s0,64(sp)
    80004992:	74e2                	ld	s1,56(sp)
    80004994:	7942                	ld	s2,48(sp)
    80004996:	79a2                	ld	s3,40(sp)
    80004998:	6161                	addi	sp,sp,80
    8000499a:	8082                	ret
  return -1;
    8000499c:	557d                	li	a0,-1
    8000499e:	bfc5                	j	8000498e <filestat+0x60>

00000000800049a0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049a0:	7179                	addi	sp,sp,-48
    800049a2:	f406                	sd	ra,40(sp)
    800049a4:	f022                	sd	s0,32(sp)
    800049a6:	ec26                	sd	s1,24(sp)
    800049a8:	e84a                	sd	s2,16(sp)
    800049aa:	e44e                	sd	s3,8(sp)
    800049ac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049ae:	00854783          	lbu	a5,8(a0)
    800049b2:	c3d5                	beqz	a5,80004a56 <fileread+0xb6>
    800049b4:	84aa                	mv	s1,a0
    800049b6:	89ae                	mv	s3,a1
    800049b8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ba:	411c                	lw	a5,0(a0)
    800049bc:	4705                	li	a4,1
    800049be:	04e78963          	beq	a5,a4,80004a10 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049c2:	470d                	li	a4,3
    800049c4:	04e78d63          	beq	a5,a4,80004a1e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c8:	4709                	li	a4,2
    800049ca:	06e79e63          	bne	a5,a4,80004a46 <fileread+0xa6>
    ilock(f->ip);
    800049ce:	6d08                	ld	a0,24(a0)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	ff8080e7          	jalr	-8(ra) # 800039c8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049d8:	874a                	mv	a4,s2
    800049da:	5094                	lw	a3,32(s1)
    800049dc:	864e                	mv	a2,s3
    800049de:	4585                	li	a1,1
    800049e0:	6c88                	ld	a0,24(s1)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	29a080e7          	jalr	666(ra) # 80003c7c <readi>
    800049ea:	892a                	mv	s2,a0
    800049ec:	00a05563          	blez	a0,800049f6 <fileread+0x56>
      f->off += r;
    800049f0:	509c                	lw	a5,32(s1)
    800049f2:	9fa9                	addw	a5,a5,a0
    800049f4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049f6:	6c88                	ld	a0,24(s1)
    800049f8:	fffff097          	auipc	ra,0xfffff
    800049fc:	092080e7          	jalr	146(ra) # 80003a8a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a00:	854a                	mv	a0,s2
    80004a02:	70a2                	ld	ra,40(sp)
    80004a04:	7402                	ld	s0,32(sp)
    80004a06:	64e2                	ld	s1,24(sp)
    80004a08:	6942                	ld	s2,16(sp)
    80004a0a:	69a2                	ld	s3,8(sp)
    80004a0c:	6145                	addi	sp,sp,48
    80004a0e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a10:	6908                	ld	a0,16(a0)
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	3c8080e7          	jalr	968(ra) # 80004dda <piperead>
    80004a1a:	892a                	mv	s2,a0
    80004a1c:	b7d5                	j	80004a00 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a1e:	02451783          	lh	a5,36(a0)
    80004a22:	03079693          	slli	a3,a5,0x30
    80004a26:	92c1                	srli	a3,a3,0x30
    80004a28:	4725                	li	a4,9
    80004a2a:	02d76863          	bltu	a4,a3,80004a5a <fileread+0xba>
    80004a2e:	0792                	slli	a5,a5,0x4
    80004a30:	0001d717          	auipc	a4,0x1d
    80004a34:	32070713          	addi	a4,a4,800 # 80021d50 <devsw>
    80004a38:	97ba                	add	a5,a5,a4
    80004a3a:	639c                	ld	a5,0(a5)
    80004a3c:	c38d                	beqz	a5,80004a5e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a3e:	4505                	li	a0,1
    80004a40:	9782                	jalr	a5
    80004a42:	892a                	mv	s2,a0
    80004a44:	bf75                	j	80004a00 <fileread+0x60>
    panic("fileread");
    80004a46:	00004517          	auipc	a0,0x4
    80004a4a:	d1a50513          	addi	a0,a0,-742 # 80008760 <syscalls+0x270>
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	af0080e7          	jalr	-1296(ra) # 8000053e <panic>
    return -1;
    80004a56:	597d                	li	s2,-1
    80004a58:	b765                	j	80004a00 <fileread+0x60>
      return -1;
    80004a5a:	597d                	li	s2,-1
    80004a5c:	b755                	j	80004a00 <fileread+0x60>
    80004a5e:	597d                	li	s2,-1
    80004a60:	b745                	j	80004a00 <fileread+0x60>

0000000080004a62 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a62:	715d                	addi	sp,sp,-80
    80004a64:	e486                	sd	ra,72(sp)
    80004a66:	e0a2                	sd	s0,64(sp)
    80004a68:	fc26                	sd	s1,56(sp)
    80004a6a:	f84a                	sd	s2,48(sp)
    80004a6c:	f44e                	sd	s3,40(sp)
    80004a6e:	f052                	sd	s4,32(sp)
    80004a70:	ec56                	sd	s5,24(sp)
    80004a72:	e85a                	sd	s6,16(sp)
    80004a74:	e45e                	sd	s7,8(sp)
    80004a76:	e062                	sd	s8,0(sp)
    80004a78:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a7a:	00954783          	lbu	a5,9(a0)
    80004a7e:	10078663          	beqz	a5,80004b8a <filewrite+0x128>
    80004a82:	892a                	mv	s2,a0
    80004a84:	8aae                	mv	s5,a1
    80004a86:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a88:	411c                	lw	a5,0(a0)
    80004a8a:	4705                	li	a4,1
    80004a8c:	02e78263          	beq	a5,a4,80004ab0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a90:	470d                	li	a4,3
    80004a92:	02e78663          	beq	a5,a4,80004abe <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a96:	4709                	li	a4,2
    80004a98:	0ee79163          	bne	a5,a4,80004b7a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a9c:	0ac05d63          	blez	a2,80004b56 <filewrite+0xf4>
    int i = 0;
    80004aa0:	4981                	li	s3,0
    80004aa2:	6b05                	lui	s6,0x1
    80004aa4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aa8:	6b85                	lui	s7,0x1
    80004aaa:	c00b8b9b          	addiw	s7,s7,-1024
    80004aae:	a861                	j	80004b46 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ab0:	6908                	ld	a0,16(a0)
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	22e080e7          	jalr	558(ra) # 80004ce0 <pipewrite>
    80004aba:	8a2a                	mv	s4,a0
    80004abc:	a045                	j	80004b5c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004abe:	02451783          	lh	a5,36(a0)
    80004ac2:	03079693          	slli	a3,a5,0x30
    80004ac6:	92c1                	srli	a3,a3,0x30
    80004ac8:	4725                	li	a4,9
    80004aca:	0cd76263          	bltu	a4,a3,80004b8e <filewrite+0x12c>
    80004ace:	0792                	slli	a5,a5,0x4
    80004ad0:	0001d717          	auipc	a4,0x1d
    80004ad4:	28070713          	addi	a4,a4,640 # 80021d50 <devsw>
    80004ad8:	97ba                	add	a5,a5,a4
    80004ada:	679c                	ld	a5,8(a5)
    80004adc:	cbdd                	beqz	a5,80004b92 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ade:	4505                	li	a0,1
    80004ae0:	9782                	jalr	a5
    80004ae2:	8a2a                	mv	s4,a0
    80004ae4:	a8a5                	j	80004b5c <filewrite+0xfa>
    80004ae6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004aea:	00000097          	auipc	ra,0x0
    80004aee:	8b0080e7          	jalr	-1872(ra) # 8000439a <begin_op>
      ilock(f->ip);
    80004af2:	01893503          	ld	a0,24(s2)
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	ed2080e7          	jalr	-302(ra) # 800039c8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004afe:	8762                	mv	a4,s8
    80004b00:	02092683          	lw	a3,32(s2)
    80004b04:	01598633          	add	a2,s3,s5
    80004b08:	4585                	li	a1,1
    80004b0a:	01893503          	ld	a0,24(s2)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	266080e7          	jalr	614(ra) # 80003d74 <writei>
    80004b16:	84aa                	mv	s1,a0
    80004b18:	00a05763          	blez	a0,80004b26 <filewrite+0xc4>
        f->off += r;
    80004b1c:	02092783          	lw	a5,32(s2)
    80004b20:	9fa9                	addw	a5,a5,a0
    80004b22:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b26:	01893503          	ld	a0,24(s2)
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	f60080e7          	jalr	-160(ra) # 80003a8a <iunlock>
      end_op();
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	8e8080e7          	jalr	-1816(ra) # 8000441a <end_op>

      if(r != n1){
    80004b3a:	009c1f63          	bne	s8,s1,80004b58 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b3e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b42:	0149db63          	bge	s3,s4,80004b58 <filewrite+0xf6>
      int n1 = n - i;
    80004b46:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b4a:	84be                	mv	s1,a5
    80004b4c:	2781                	sext.w	a5,a5
    80004b4e:	f8fb5ce3          	bge	s6,a5,80004ae6 <filewrite+0x84>
    80004b52:	84de                	mv	s1,s7
    80004b54:	bf49                	j	80004ae6 <filewrite+0x84>
    int i = 0;
    80004b56:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b58:	013a1f63          	bne	s4,s3,80004b76 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b5c:	8552                	mv	a0,s4
    80004b5e:	60a6                	ld	ra,72(sp)
    80004b60:	6406                	ld	s0,64(sp)
    80004b62:	74e2                	ld	s1,56(sp)
    80004b64:	7942                	ld	s2,48(sp)
    80004b66:	79a2                	ld	s3,40(sp)
    80004b68:	7a02                	ld	s4,32(sp)
    80004b6a:	6ae2                	ld	s5,24(sp)
    80004b6c:	6b42                	ld	s6,16(sp)
    80004b6e:	6ba2                	ld	s7,8(sp)
    80004b70:	6c02                	ld	s8,0(sp)
    80004b72:	6161                	addi	sp,sp,80
    80004b74:	8082                	ret
    ret = (i == n ? n : -1);
    80004b76:	5a7d                	li	s4,-1
    80004b78:	b7d5                	j	80004b5c <filewrite+0xfa>
    panic("filewrite");
    80004b7a:	00004517          	auipc	a0,0x4
    80004b7e:	bf650513          	addi	a0,a0,-1034 # 80008770 <syscalls+0x280>
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>
    return -1;
    80004b8a:	5a7d                	li	s4,-1
    80004b8c:	bfc1                	j	80004b5c <filewrite+0xfa>
      return -1;
    80004b8e:	5a7d                	li	s4,-1
    80004b90:	b7f1                	j	80004b5c <filewrite+0xfa>
    80004b92:	5a7d                	li	s4,-1
    80004b94:	b7e1                	j	80004b5c <filewrite+0xfa>

0000000080004b96 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b96:	7179                	addi	sp,sp,-48
    80004b98:	f406                	sd	ra,40(sp)
    80004b9a:	f022                	sd	s0,32(sp)
    80004b9c:	ec26                	sd	s1,24(sp)
    80004b9e:	e84a                	sd	s2,16(sp)
    80004ba0:	e44e                	sd	s3,8(sp)
    80004ba2:	e052                	sd	s4,0(sp)
    80004ba4:	1800                	addi	s0,sp,48
    80004ba6:	84aa                	mv	s1,a0
    80004ba8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004baa:	0005b023          	sd	zero,0(a1)
    80004bae:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	bf8080e7          	jalr	-1032(ra) # 800047aa <filealloc>
    80004bba:	e088                	sd	a0,0(s1)
    80004bbc:	c551                	beqz	a0,80004c48 <pipealloc+0xb2>
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	bec080e7          	jalr	-1044(ra) # 800047aa <filealloc>
    80004bc6:	00aa3023          	sd	a0,0(s4)
    80004bca:	c92d                	beqz	a0,80004c3c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	f28080e7          	jalr	-216(ra) # 80000af4 <kalloc>
    80004bd4:	892a                	mv	s2,a0
    80004bd6:	c125                	beqz	a0,80004c36 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bd8:	4985                	li	s3,1
    80004bda:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bde:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004be2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004be6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bea:	00004597          	auipc	a1,0x4
    80004bee:	b9658593          	addi	a1,a1,-1130 # 80008780 <syscalls+0x290>
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	f62080e7          	jalr	-158(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004bfa:	609c                	ld	a5,0(s1)
    80004bfc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c00:	609c                	ld	a5,0(s1)
    80004c02:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c06:	609c                	ld	a5,0(s1)
    80004c08:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c0c:	609c                	ld	a5,0(s1)
    80004c0e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c12:	000a3783          	ld	a5,0(s4)
    80004c16:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c1a:	000a3783          	ld	a5,0(s4)
    80004c1e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c22:	000a3783          	ld	a5,0(s4)
    80004c26:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c2a:	000a3783          	ld	a5,0(s4)
    80004c2e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c32:	4501                	li	a0,0
    80004c34:	a025                	j	80004c5c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c36:	6088                	ld	a0,0(s1)
    80004c38:	e501                	bnez	a0,80004c40 <pipealloc+0xaa>
    80004c3a:	a039                	j	80004c48 <pipealloc+0xb2>
    80004c3c:	6088                	ld	a0,0(s1)
    80004c3e:	c51d                	beqz	a0,80004c6c <pipealloc+0xd6>
    fileclose(*f0);
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	c26080e7          	jalr	-986(ra) # 80004866 <fileclose>
  if(*f1)
    80004c48:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c4c:	557d                	li	a0,-1
  if(*f1)
    80004c4e:	c799                	beqz	a5,80004c5c <pipealloc+0xc6>
    fileclose(*f1);
    80004c50:	853e                	mv	a0,a5
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	c14080e7          	jalr	-1004(ra) # 80004866 <fileclose>
  return -1;
    80004c5a:	557d                	li	a0,-1
}
    80004c5c:	70a2                	ld	ra,40(sp)
    80004c5e:	7402                	ld	s0,32(sp)
    80004c60:	64e2                	ld	s1,24(sp)
    80004c62:	6942                	ld	s2,16(sp)
    80004c64:	69a2                	ld	s3,8(sp)
    80004c66:	6a02                	ld	s4,0(sp)
    80004c68:	6145                	addi	sp,sp,48
    80004c6a:	8082                	ret
  return -1;
    80004c6c:	557d                	li	a0,-1
    80004c6e:	b7fd                	j	80004c5c <pipealloc+0xc6>

0000000080004c70 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c70:	1101                	addi	sp,sp,-32
    80004c72:	ec06                	sd	ra,24(sp)
    80004c74:	e822                	sd	s0,16(sp)
    80004c76:	e426                	sd	s1,8(sp)
    80004c78:	e04a                	sd	s2,0(sp)
    80004c7a:	1000                	addi	s0,sp,32
    80004c7c:	84aa                	mv	s1,a0
    80004c7e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	f64080e7          	jalr	-156(ra) # 80000be4 <acquire>
  if(writable){
    80004c88:	02090d63          	beqz	s2,80004cc2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c8c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c90:	21848513          	addi	a0,s1,536
    80004c94:	ffffe097          	auipc	ra,0xffffe
    80004c98:	908080e7          	jalr	-1784(ra) # 8000259c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c9c:	2204b783          	ld	a5,544(s1)
    80004ca0:	eb95                	bnez	a5,80004cd4 <pipeclose+0x64>
    release(&pi->lock);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	d4a080e7          	jalr	-694(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004cb6:	60e2                	ld	ra,24(sp)
    80004cb8:	6442                	ld	s0,16(sp)
    80004cba:	64a2                	ld	s1,8(sp)
    80004cbc:	6902                	ld	s2,0(sp)
    80004cbe:	6105                	addi	sp,sp,32
    80004cc0:	8082                	ret
    pi->readopen = 0;
    80004cc2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cc6:	21c48513          	addi	a0,s1,540
    80004cca:	ffffe097          	auipc	ra,0xffffe
    80004cce:	8d2080e7          	jalr	-1838(ra) # 8000259c <wakeup>
    80004cd2:	b7e9                	j	80004c9c <pipeclose+0x2c>
    release(&pi->lock);
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	fc2080e7          	jalr	-62(ra) # 80000c98 <release>
}
    80004cde:	bfe1                	j	80004cb6 <pipeclose+0x46>

0000000080004ce0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ce0:	7159                	addi	sp,sp,-112
    80004ce2:	f486                	sd	ra,104(sp)
    80004ce4:	f0a2                	sd	s0,96(sp)
    80004ce6:	eca6                	sd	s1,88(sp)
    80004ce8:	e8ca                	sd	s2,80(sp)
    80004cea:	e4ce                	sd	s3,72(sp)
    80004cec:	e0d2                	sd	s4,64(sp)
    80004cee:	fc56                	sd	s5,56(sp)
    80004cf0:	f85a                	sd	s6,48(sp)
    80004cf2:	f45e                	sd	s7,40(sp)
    80004cf4:	f062                	sd	s8,32(sp)
    80004cf6:	ec66                	sd	s9,24(sp)
    80004cf8:	1880                	addi	s0,sp,112
    80004cfa:	84aa                	mv	s1,a0
    80004cfc:	8aae                	mv	s5,a1
    80004cfe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	cc0080e7          	jalr	-832(ra) # 800019c0 <myproc>
    80004d08:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	ed8080e7          	jalr	-296(ra) # 80000be4 <acquire>
  while(i < n){
    80004d14:	0d405163          	blez	s4,80004dd6 <pipewrite+0xf6>
    80004d18:	8ba6                	mv	s7,s1
  int i = 0;
    80004d1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d1e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d22:	21c48c13          	addi	s8,s1,540
    80004d26:	a08d                	j	80004d88 <pipewrite+0xa8>
      release(&pi->lock);
    80004d28:	8526                	mv	a0,s1
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	f6e080e7          	jalr	-146(ra) # 80000c98 <release>
      return -1;
    80004d32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d34:	854a                	mv	a0,s2
    80004d36:	70a6                	ld	ra,104(sp)
    80004d38:	7406                	ld	s0,96(sp)
    80004d3a:	64e6                	ld	s1,88(sp)
    80004d3c:	6946                	ld	s2,80(sp)
    80004d3e:	69a6                	ld	s3,72(sp)
    80004d40:	6a06                	ld	s4,64(sp)
    80004d42:	7ae2                	ld	s5,56(sp)
    80004d44:	7b42                	ld	s6,48(sp)
    80004d46:	7ba2                	ld	s7,40(sp)
    80004d48:	7c02                	ld	s8,32(sp)
    80004d4a:	6ce2                	ld	s9,24(sp)
    80004d4c:	6165                	addi	sp,sp,112
    80004d4e:	8082                	ret
      wakeup(&pi->nread);
    80004d50:	8566                	mv	a0,s9
    80004d52:	ffffe097          	auipc	ra,0xffffe
    80004d56:	84a080e7          	jalr	-1974(ra) # 8000259c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d5a:	85de                	mv	a1,s7
    80004d5c:	8562                	mv	a0,s8
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	6a6080e7          	jalr	1702(ra) # 80002404 <sleep>
    80004d66:	a839                	j	80004d84 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d68:	21c4a783          	lw	a5,540(s1)
    80004d6c:	0017871b          	addiw	a4,a5,1
    80004d70:	20e4ae23          	sw	a4,540(s1)
    80004d74:	1ff7f793          	andi	a5,a5,511
    80004d78:	97a6                	add	a5,a5,s1
    80004d7a:	f9f44703          	lbu	a4,-97(s0)
    80004d7e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d82:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d84:	03495d63          	bge	s2,s4,80004dbe <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d88:	2204a783          	lw	a5,544(s1)
    80004d8c:	dfd1                	beqz	a5,80004d28 <pipewrite+0x48>
    80004d8e:	0289a783          	lw	a5,40(s3)
    80004d92:	fbd9                	bnez	a5,80004d28 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d94:	2184a783          	lw	a5,536(s1)
    80004d98:	21c4a703          	lw	a4,540(s1)
    80004d9c:	2007879b          	addiw	a5,a5,512
    80004da0:	faf708e3          	beq	a4,a5,80004d50 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da4:	4685                	li	a3,1
    80004da6:	01590633          	add	a2,s2,s5
    80004daa:	f9f40593          	addi	a1,s0,-97
    80004dae:	0789b503          	ld	a0,120(s3)
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	94c080e7          	jalr	-1716(ra) # 800016fe <copyin>
    80004dba:	fb6517e3          	bne	a0,s6,80004d68 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004dbe:	21848513          	addi	a0,s1,536
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	7da080e7          	jalr	2010(ra) # 8000259c <wakeup>
  release(&pi->lock);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
  return i;
    80004dd4:	b785                	j	80004d34 <pipewrite+0x54>
  int i = 0;
    80004dd6:	4901                	li	s2,0
    80004dd8:	b7dd                	j	80004dbe <pipewrite+0xde>

0000000080004dda <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dda:	715d                	addi	sp,sp,-80
    80004ddc:	e486                	sd	ra,72(sp)
    80004dde:	e0a2                	sd	s0,64(sp)
    80004de0:	fc26                	sd	s1,56(sp)
    80004de2:	f84a                	sd	s2,48(sp)
    80004de4:	f44e                	sd	s3,40(sp)
    80004de6:	f052                	sd	s4,32(sp)
    80004de8:	ec56                	sd	s5,24(sp)
    80004dea:	e85a                	sd	s6,16(sp)
    80004dec:	0880                	addi	s0,sp,80
    80004dee:	84aa                	mv	s1,a0
    80004df0:	892e                	mv	s2,a1
    80004df2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	bcc080e7          	jalr	-1076(ra) # 800019c0 <myproc>
    80004dfc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dfe:	8b26                	mv	s6,s1
    80004e00:	8526                	mv	a0,s1
    80004e02:	ffffc097          	auipc	ra,0xffffc
    80004e06:	de2080e7          	jalr	-542(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e0a:	2184a703          	lw	a4,536(s1)
    80004e0e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e12:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e16:	02f71463          	bne	a4,a5,80004e3e <piperead+0x64>
    80004e1a:	2244a783          	lw	a5,548(s1)
    80004e1e:	c385                	beqz	a5,80004e3e <piperead+0x64>
    if(pr->killed){
    80004e20:	028a2783          	lw	a5,40(s4)
    80004e24:	ebc1                	bnez	a5,80004eb4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e26:	85da                	mv	a1,s6
    80004e28:	854e                	mv	a0,s3
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	5da080e7          	jalr	1498(ra) # 80002404 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e32:	2184a703          	lw	a4,536(s1)
    80004e36:	21c4a783          	lw	a5,540(s1)
    80004e3a:	fef700e3          	beq	a4,a5,80004e1a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e3e:	09505263          	blez	s5,80004ec2 <piperead+0xe8>
    80004e42:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e44:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e46:	2184a783          	lw	a5,536(s1)
    80004e4a:	21c4a703          	lw	a4,540(s1)
    80004e4e:	02f70d63          	beq	a4,a5,80004e88 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e52:	0017871b          	addiw	a4,a5,1
    80004e56:	20e4ac23          	sw	a4,536(s1)
    80004e5a:	1ff7f793          	andi	a5,a5,511
    80004e5e:	97a6                	add	a5,a5,s1
    80004e60:	0187c783          	lbu	a5,24(a5)
    80004e64:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e68:	4685                	li	a3,1
    80004e6a:	fbf40613          	addi	a2,s0,-65
    80004e6e:	85ca                	mv	a1,s2
    80004e70:	078a3503          	ld	a0,120(s4)
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	7fe080e7          	jalr	2046(ra) # 80001672 <copyout>
    80004e7c:	01650663          	beq	a0,s6,80004e88 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e80:	2985                	addiw	s3,s3,1
    80004e82:	0905                	addi	s2,s2,1
    80004e84:	fd3a91e3          	bne	s5,s3,80004e46 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e88:	21c48513          	addi	a0,s1,540
    80004e8c:	ffffd097          	auipc	ra,0xffffd
    80004e90:	710080e7          	jalr	1808(ra) # 8000259c <wakeup>
  release(&pi->lock);
    80004e94:	8526                	mv	a0,s1
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
  return i;
}
    80004e9e:	854e                	mv	a0,s3
    80004ea0:	60a6                	ld	ra,72(sp)
    80004ea2:	6406                	ld	s0,64(sp)
    80004ea4:	74e2                	ld	s1,56(sp)
    80004ea6:	7942                	ld	s2,48(sp)
    80004ea8:	79a2                	ld	s3,40(sp)
    80004eaa:	7a02                	ld	s4,32(sp)
    80004eac:	6ae2                	ld	s5,24(sp)
    80004eae:	6b42                	ld	s6,16(sp)
    80004eb0:	6161                	addi	sp,sp,80
    80004eb2:	8082                	ret
      release(&pi->lock);
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	de2080e7          	jalr	-542(ra) # 80000c98 <release>
      return -1;
    80004ebe:	59fd                	li	s3,-1
    80004ec0:	bff9                	j	80004e9e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec2:	4981                	li	s3,0
    80004ec4:	b7d1                	j	80004e88 <piperead+0xae>

0000000080004ec6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ec6:	df010113          	addi	sp,sp,-528
    80004eca:	20113423          	sd	ra,520(sp)
    80004ece:	20813023          	sd	s0,512(sp)
    80004ed2:	ffa6                	sd	s1,504(sp)
    80004ed4:	fbca                	sd	s2,496(sp)
    80004ed6:	f7ce                	sd	s3,488(sp)
    80004ed8:	f3d2                	sd	s4,480(sp)
    80004eda:	efd6                	sd	s5,472(sp)
    80004edc:	ebda                	sd	s6,464(sp)
    80004ede:	e7de                	sd	s7,456(sp)
    80004ee0:	e3e2                	sd	s8,448(sp)
    80004ee2:	ff66                	sd	s9,440(sp)
    80004ee4:	fb6a                	sd	s10,432(sp)
    80004ee6:	f76e                	sd	s11,424(sp)
    80004ee8:	0c00                	addi	s0,sp,528
    80004eea:	84aa                	mv	s1,a0
    80004eec:	dea43c23          	sd	a0,-520(s0)
    80004ef0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	acc080e7          	jalr	-1332(ra) # 800019c0 <myproc>
    80004efc:	892a                	mv	s2,a0

  begin_op();
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	49c080e7          	jalr	1180(ra) # 8000439a <begin_op>

  if((ip = namei(path)) == 0){
    80004f06:	8526                	mv	a0,s1
    80004f08:	fffff097          	auipc	ra,0xfffff
    80004f0c:	276080e7          	jalr	630(ra) # 8000417e <namei>
    80004f10:	c92d                	beqz	a0,80004f82 <exec+0xbc>
    80004f12:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	ab4080e7          	jalr	-1356(ra) # 800039c8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f1c:	04000713          	li	a4,64
    80004f20:	4681                	li	a3,0
    80004f22:	e5040613          	addi	a2,s0,-432
    80004f26:	4581                	li	a1,0
    80004f28:	8526                	mv	a0,s1
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	d52080e7          	jalr	-686(ra) # 80003c7c <readi>
    80004f32:	04000793          	li	a5,64
    80004f36:	00f51a63          	bne	a0,a5,80004f4a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f3a:	e5042703          	lw	a4,-432(s0)
    80004f3e:	464c47b7          	lui	a5,0x464c4
    80004f42:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f46:	04f70463          	beq	a4,a5,80004f8e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f4a:	8526                	mv	a0,s1
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	cde080e7          	jalr	-802(ra) # 80003c2a <iunlockput>
    end_op();
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	4c6080e7          	jalr	1222(ra) # 8000441a <end_op>
  }
  return -1;
    80004f5c:	557d                	li	a0,-1
}
    80004f5e:	20813083          	ld	ra,520(sp)
    80004f62:	20013403          	ld	s0,512(sp)
    80004f66:	74fe                	ld	s1,504(sp)
    80004f68:	795e                	ld	s2,496(sp)
    80004f6a:	79be                	ld	s3,488(sp)
    80004f6c:	7a1e                	ld	s4,480(sp)
    80004f6e:	6afe                	ld	s5,472(sp)
    80004f70:	6b5e                	ld	s6,464(sp)
    80004f72:	6bbe                	ld	s7,456(sp)
    80004f74:	6c1e                	ld	s8,448(sp)
    80004f76:	7cfa                	ld	s9,440(sp)
    80004f78:	7d5a                	ld	s10,432(sp)
    80004f7a:	7dba                	ld	s11,424(sp)
    80004f7c:	21010113          	addi	sp,sp,528
    80004f80:	8082                	ret
    end_op();
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	498080e7          	jalr	1176(ra) # 8000441a <end_op>
    return -1;
    80004f8a:	557d                	li	a0,-1
    80004f8c:	bfc9                	j	80004f5e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f8e:	854a                	mv	a0,s2
    80004f90:	ffffd097          	auipc	ra,0xffffd
    80004f94:	af4080e7          	jalr	-1292(ra) # 80001a84 <proc_pagetable>
    80004f98:	8baa                	mv	s7,a0
    80004f9a:	d945                	beqz	a0,80004f4a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f9c:	e7042983          	lw	s3,-400(s0)
    80004fa0:	e8845783          	lhu	a5,-376(s0)
    80004fa4:	c7ad                	beqz	a5,8000500e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fa6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004faa:	6c85                	lui	s9,0x1
    80004fac:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fb0:	def43823          	sd	a5,-528(s0)
    80004fb4:	a42d                	j	800051de <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fb6:	00003517          	auipc	a0,0x3
    80004fba:	7d250513          	addi	a0,a0,2002 # 80008788 <syscalls+0x298>
    80004fbe:	ffffb097          	auipc	ra,0xffffb
    80004fc2:	580080e7          	jalr	1408(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fc6:	8756                	mv	a4,s5
    80004fc8:	012d86bb          	addw	a3,s11,s2
    80004fcc:	4581                	li	a1,0
    80004fce:	8526                	mv	a0,s1
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	cac080e7          	jalr	-852(ra) # 80003c7c <readi>
    80004fd8:	2501                	sext.w	a0,a0
    80004fda:	1aaa9963          	bne	s5,a0,8000518c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fde:	6785                	lui	a5,0x1
    80004fe0:	0127893b          	addw	s2,a5,s2
    80004fe4:	77fd                	lui	a5,0xfffff
    80004fe6:	01478a3b          	addw	s4,a5,s4
    80004fea:	1f897163          	bgeu	s2,s8,800051cc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fee:	02091593          	slli	a1,s2,0x20
    80004ff2:	9181                	srli	a1,a1,0x20
    80004ff4:	95ea                	add	a1,a1,s10
    80004ff6:	855e                	mv	a0,s7
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	076080e7          	jalr	118(ra) # 8000106e <walkaddr>
    80005000:	862a                	mv	a2,a0
    if(pa == 0)
    80005002:	d955                	beqz	a0,80004fb6 <exec+0xf0>
      n = PGSIZE;
    80005004:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005006:	fd9a70e3          	bgeu	s4,s9,80004fc6 <exec+0x100>
      n = sz - i;
    8000500a:	8ad2                	mv	s5,s4
    8000500c:	bf6d                	j	80004fc6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000500e:	4901                	li	s2,0
  iunlockput(ip);
    80005010:	8526                	mv	a0,s1
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	c18080e7          	jalr	-1000(ra) # 80003c2a <iunlockput>
  end_op();
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	400080e7          	jalr	1024(ra) # 8000441a <end_op>
  p = myproc();
    80005022:	ffffd097          	auipc	ra,0xffffd
    80005026:	99e080e7          	jalr	-1634(ra) # 800019c0 <myproc>
    8000502a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000502c:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005030:	6785                	lui	a5,0x1
    80005032:	17fd                	addi	a5,a5,-1
    80005034:	993e                	add	s2,s2,a5
    80005036:	757d                	lui	a0,0xfffff
    80005038:	00a977b3          	and	a5,s2,a0
    8000503c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005040:	6609                	lui	a2,0x2
    80005042:	963e                	add	a2,a2,a5
    80005044:	85be                	mv	a1,a5
    80005046:	855e                	mv	a0,s7
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	3da080e7          	jalr	986(ra) # 80001422 <uvmalloc>
    80005050:	8b2a                	mv	s6,a0
  ip = 0;
    80005052:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005054:	12050c63          	beqz	a0,8000518c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005058:	75f9                	lui	a1,0xffffe
    8000505a:	95aa                	add	a1,a1,a0
    8000505c:	855e                	mv	a0,s7
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	5e2080e7          	jalr	1506(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005066:	7c7d                	lui	s8,0xfffff
    80005068:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000506a:	e0043783          	ld	a5,-512(s0)
    8000506e:	6388                	ld	a0,0(a5)
    80005070:	c535                	beqz	a0,800050dc <exec+0x216>
    80005072:	e9040993          	addi	s3,s0,-368
    80005076:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000507a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	de8080e7          	jalr	-536(ra) # 80000e64 <strlen>
    80005084:	2505                	addiw	a0,a0,1
    80005086:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000508a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000508e:	13896363          	bltu	s2,s8,800051b4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005092:	e0043d83          	ld	s11,-512(s0)
    80005096:	000dba03          	ld	s4,0(s11)
    8000509a:	8552                	mv	a0,s4
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	dc8080e7          	jalr	-568(ra) # 80000e64 <strlen>
    800050a4:	0015069b          	addiw	a3,a0,1
    800050a8:	8652                	mv	a2,s4
    800050aa:	85ca                	mv	a1,s2
    800050ac:	855e                	mv	a0,s7
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	5c4080e7          	jalr	1476(ra) # 80001672 <copyout>
    800050b6:	10054363          	bltz	a0,800051bc <exec+0x2f6>
    ustack[argc] = sp;
    800050ba:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050be:	0485                	addi	s1,s1,1
    800050c0:	008d8793          	addi	a5,s11,8
    800050c4:	e0f43023          	sd	a5,-512(s0)
    800050c8:	008db503          	ld	a0,8(s11)
    800050cc:	c911                	beqz	a0,800050e0 <exec+0x21a>
    if(argc >= MAXARG)
    800050ce:	09a1                	addi	s3,s3,8
    800050d0:	fb3c96e3          	bne	s9,s3,8000507c <exec+0x1b6>
  sz = sz1;
    800050d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d8:	4481                	li	s1,0
    800050da:	a84d                	j	8000518c <exec+0x2c6>
  sp = sz;
    800050dc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050de:	4481                	li	s1,0
  ustack[argc] = 0;
    800050e0:	00349793          	slli	a5,s1,0x3
    800050e4:	f9040713          	addi	a4,s0,-112
    800050e8:	97ba                	add	a5,a5,a4
    800050ea:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050ee:	00148693          	addi	a3,s1,1
    800050f2:	068e                	slli	a3,a3,0x3
    800050f4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050f8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050fc:	01897663          	bgeu	s2,s8,80005108 <exec+0x242>
  sz = sz1;
    80005100:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005104:	4481                	li	s1,0
    80005106:	a059                	j	8000518c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005108:	e9040613          	addi	a2,s0,-368
    8000510c:	85ca                	mv	a1,s2
    8000510e:	855e                	mv	a0,s7
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	562080e7          	jalr	1378(ra) # 80001672 <copyout>
    80005118:	0a054663          	bltz	a0,800051c4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000511c:	080ab783          	ld	a5,128(s5)
    80005120:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005124:	df843783          	ld	a5,-520(s0)
    80005128:	0007c703          	lbu	a4,0(a5)
    8000512c:	cf11                	beqz	a4,80005148 <exec+0x282>
    8000512e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005130:	02f00693          	li	a3,47
    80005134:	a039                	j	80005142 <exec+0x27c>
      last = s+1;
    80005136:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000513a:	0785                	addi	a5,a5,1
    8000513c:	fff7c703          	lbu	a4,-1(a5)
    80005140:	c701                	beqz	a4,80005148 <exec+0x282>
    if(*s == '/')
    80005142:	fed71ce3          	bne	a4,a3,8000513a <exec+0x274>
    80005146:	bfc5                	j	80005136 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005148:	4641                	li	a2,16
    8000514a:	df843583          	ld	a1,-520(s0)
    8000514e:	180a8513          	addi	a0,s5,384
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	ce0080e7          	jalr	-800(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000515a:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    8000515e:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005162:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005166:	080ab783          	ld	a5,128(s5)
    8000516a:	e6843703          	ld	a4,-408(s0)
    8000516e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005170:	080ab783          	ld	a5,128(s5)
    80005174:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005178:	85ea                	mv	a1,s10
    8000517a:	ffffd097          	auipc	ra,0xffffd
    8000517e:	9a6080e7          	jalr	-1626(ra) # 80001b20 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005182:	0004851b          	sext.w	a0,s1
    80005186:	bbe1                	j	80004f5e <exec+0x98>
    80005188:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000518c:	e0843583          	ld	a1,-504(s0)
    80005190:	855e                	mv	a0,s7
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	98e080e7          	jalr	-1650(ra) # 80001b20 <proc_freepagetable>
  if(ip){
    8000519a:	da0498e3          	bnez	s1,80004f4a <exec+0x84>
  return -1;
    8000519e:	557d                	li	a0,-1
    800051a0:	bb7d                	j	80004f5e <exec+0x98>
    800051a2:	e1243423          	sd	s2,-504(s0)
    800051a6:	b7dd                	j	8000518c <exec+0x2c6>
    800051a8:	e1243423          	sd	s2,-504(s0)
    800051ac:	b7c5                	j	8000518c <exec+0x2c6>
    800051ae:	e1243423          	sd	s2,-504(s0)
    800051b2:	bfe9                	j	8000518c <exec+0x2c6>
  sz = sz1;
    800051b4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051b8:	4481                	li	s1,0
    800051ba:	bfc9                	j	8000518c <exec+0x2c6>
  sz = sz1;
    800051bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c0:	4481                	li	s1,0
    800051c2:	b7e9                	j	8000518c <exec+0x2c6>
  sz = sz1;
    800051c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c8:	4481                	li	s1,0
    800051ca:	b7c9                	j	8000518c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051cc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d0:	2b05                	addiw	s6,s6,1
    800051d2:	0389899b          	addiw	s3,s3,56
    800051d6:	e8845783          	lhu	a5,-376(s0)
    800051da:	e2fb5be3          	bge	s6,a5,80005010 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051de:	2981                	sext.w	s3,s3
    800051e0:	03800713          	li	a4,56
    800051e4:	86ce                	mv	a3,s3
    800051e6:	e1840613          	addi	a2,s0,-488
    800051ea:	4581                	li	a1,0
    800051ec:	8526                	mv	a0,s1
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	a8e080e7          	jalr	-1394(ra) # 80003c7c <readi>
    800051f6:	03800793          	li	a5,56
    800051fa:	f8f517e3          	bne	a0,a5,80005188 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051fe:	e1842783          	lw	a5,-488(s0)
    80005202:	4705                	li	a4,1
    80005204:	fce796e3          	bne	a5,a4,800051d0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005208:	e4043603          	ld	a2,-448(s0)
    8000520c:	e3843783          	ld	a5,-456(s0)
    80005210:	f8f669e3          	bltu	a2,a5,800051a2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005214:	e2843783          	ld	a5,-472(s0)
    80005218:	963e                	add	a2,a2,a5
    8000521a:	f8f667e3          	bltu	a2,a5,800051a8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000521e:	85ca                	mv	a1,s2
    80005220:	855e                	mv	a0,s7
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	200080e7          	jalr	512(ra) # 80001422 <uvmalloc>
    8000522a:	e0a43423          	sd	a0,-504(s0)
    8000522e:	d141                	beqz	a0,800051ae <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005230:	e2843d03          	ld	s10,-472(s0)
    80005234:	df043783          	ld	a5,-528(s0)
    80005238:	00fd77b3          	and	a5,s10,a5
    8000523c:	fba1                	bnez	a5,8000518c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000523e:	e2042d83          	lw	s11,-480(s0)
    80005242:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005246:	f80c03e3          	beqz	s8,800051cc <exec+0x306>
    8000524a:	8a62                	mv	s4,s8
    8000524c:	4901                	li	s2,0
    8000524e:	b345                	j	80004fee <exec+0x128>

0000000080005250 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005250:	7179                	addi	sp,sp,-48
    80005252:	f406                	sd	ra,40(sp)
    80005254:	f022                	sd	s0,32(sp)
    80005256:	ec26                	sd	s1,24(sp)
    80005258:	e84a                	sd	s2,16(sp)
    8000525a:	1800                	addi	s0,sp,48
    8000525c:	892e                	mv	s2,a1
    8000525e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005260:	fdc40593          	addi	a1,s0,-36
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	b90080e7          	jalr	-1136(ra) # 80002df4 <argint>
    8000526c:	04054063          	bltz	a0,800052ac <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005270:	fdc42703          	lw	a4,-36(s0)
    80005274:	47bd                	li	a5,15
    80005276:	02e7ed63          	bltu	a5,a4,800052b0 <argfd+0x60>
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	746080e7          	jalr	1862(ra) # 800019c0 <myproc>
    80005282:	fdc42703          	lw	a4,-36(s0)
    80005286:	01e70793          	addi	a5,a4,30
    8000528a:	078e                	slli	a5,a5,0x3
    8000528c:	953e                	add	a0,a0,a5
    8000528e:	651c                	ld	a5,8(a0)
    80005290:	c395                	beqz	a5,800052b4 <argfd+0x64>
    return -1;
  if(pfd)
    80005292:	00090463          	beqz	s2,8000529a <argfd+0x4a>
    *pfd = fd;
    80005296:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000529a:	4501                	li	a0,0
  if(pf)
    8000529c:	c091                	beqz	s1,800052a0 <argfd+0x50>
    *pf = f;
    8000529e:	e09c                	sd	a5,0(s1)
}
    800052a0:	70a2                	ld	ra,40(sp)
    800052a2:	7402                	ld	s0,32(sp)
    800052a4:	64e2                	ld	s1,24(sp)
    800052a6:	6942                	ld	s2,16(sp)
    800052a8:	6145                	addi	sp,sp,48
    800052aa:	8082                	ret
    return -1;
    800052ac:	557d                	li	a0,-1
    800052ae:	bfcd                	j	800052a0 <argfd+0x50>
    return -1;
    800052b0:	557d                	li	a0,-1
    800052b2:	b7fd                	j	800052a0 <argfd+0x50>
    800052b4:	557d                	li	a0,-1
    800052b6:	b7ed                	j	800052a0 <argfd+0x50>

00000000800052b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052b8:	1101                	addi	sp,sp,-32
    800052ba:	ec06                	sd	ra,24(sp)
    800052bc:	e822                	sd	s0,16(sp)
    800052be:	e426                	sd	s1,8(sp)
    800052c0:	1000                	addi	s0,sp,32
    800052c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	6fc080e7          	jalr	1788(ra) # 800019c0 <myproc>
    800052cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ce:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    800052d2:	4501                	li	a0,0
    800052d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052d6:	6398                	ld	a4,0(a5)
    800052d8:	cb19                	beqz	a4,800052ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052da:	2505                	addiw	a0,a0,1
    800052dc:	07a1                	addi	a5,a5,8
    800052de:	fed51ce3          	bne	a0,a3,800052d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052e2:	557d                	li	a0,-1
}
    800052e4:	60e2                	ld	ra,24(sp)
    800052e6:	6442                	ld	s0,16(sp)
    800052e8:	64a2                	ld	s1,8(sp)
    800052ea:	6105                	addi	sp,sp,32
    800052ec:	8082                	ret
      p->ofile[fd] = f;
    800052ee:	01e50793          	addi	a5,a0,30
    800052f2:	078e                	slli	a5,a5,0x3
    800052f4:	963e                	add	a2,a2,a5
    800052f6:	e604                	sd	s1,8(a2)
      return fd;
    800052f8:	b7f5                	j	800052e4 <fdalloc+0x2c>

00000000800052fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052fa:	715d                	addi	sp,sp,-80
    800052fc:	e486                	sd	ra,72(sp)
    800052fe:	e0a2                	sd	s0,64(sp)
    80005300:	fc26                	sd	s1,56(sp)
    80005302:	f84a                	sd	s2,48(sp)
    80005304:	f44e                	sd	s3,40(sp)
    80005306:	f052                	sd	s4,32(sp)
    80005308:	ec56                	sd	s5,24(sp)
    8000530a:	0880                	addi	s0,sp,80
    8000530c:	89ae                	mv	s3,a1
    8000530e:	8ab2                	mv	s5,a2
    80005310:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005312:	fb040593          	addi	a1,s0,-80
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	e86080e7          	jalr	-378(ra) # 8000419c <nameiparent>
    8000531e:	892a                	mv	s2,a0
    80005320:	12050f63          	beqz	a0,8000545e <create+0x164>
    return 0;

  ilock(dp);
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	6a4080e7          	jalr	1700(ra) # 800039c8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000532c:	4601                	li	a2,0
    8000532e:	fb040593          	addi	a1,s0,-80
    80005332:	854a                	mv	a0,s2
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	b78080e7          	jalr	-1160(ra) # 80003eac <dirlookup>
    8000533c:	84aa                	mv	s1,a0
    8000533e:	c921                	beqz	a0,8000538e <create+0x94>
    iunlockput(dp);
    80005340:	854a                	mv	a0,s2
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	8e8080e7          	jalr	-1816(ra) # 80003c2a <iunlockput>
    ilock(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	67c080e7          	jalr	1660(ra) # 800039c8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005354:	2981                	sext.w	s3,s3
    80005356:	4789                	li	a5,2
    80005358:	02f99463          	bne	s3,a5,80005380 <create+0x86>
    8000535c:	0444d783          	lhu	a5,68(s1)
    80005360:	37f9                	addiw	a5,a5,-2
    80005362:	17c2                	slli	a5,a5,0x30
    80005364:	93c1                	srli	a5,a5,0x30
    80005366:	4705                	li	a4,1
    80005368:	00f76c63          	bltu	a4,a5,80005380 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000536c:	8526                	mv	a0,s1
    8000536e:	60a6                	ld	ra,72(sp)
    80005370:	6406                	ld	s0,64(sp)
    80005372:	74e2                	ld	s1,56(sp)
    80005374:	7942                	ld	s2,48(sp)
    80005376:	79a2                	ld	s3,40(sp)
    80005378:	7a02                	ld	s4,32(sp)
    8000537a:	6ae2                	ld	s5,24(sp)
    8000537c:	6161                	addi	sp,sp,80
    8000537e:	8082                	ret
    iunlockput(ip);
    80005380:	8526                	mv	a0,s1
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	8a8080e7          	jalr	-1880(ra) # 80003c2a <iunlockput>
    return 0;
    8000538a:	4481                	li	s1,0
    8000538c:	b7c5                	j	8000536c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000538e:	85ce                	mv	a1,s3
    80005390:	00092503          	lw	a0,0(s2)
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	49c080e7          	jalr	1180(ra) # 80003830 <ialloc>
    8000539c:	84aa                	mv	s1,a0
    8000539e:	c529                	beqz	a0,800053e8 <create+0xee>
  ilock(ip);
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	628080e7          	jalr	1576(ra) # 800039c8 <ilock>
  ip->major = major;
    800053a8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053ac:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053b0:	4785                	li	a5,1
    800053b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053b6:	8526                	mv	a0,s1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	546080e7          	jalr	1350(ra) # 800038fe <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053c0:	2981                	sext.w	s3,s3
    800053c2:	4785                	li	a5,1
    800053c4:	02f98a63          	beq	s3,a5,800053f8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053c8:	40d0                	lw	a2,4(s1)
    800053ca:	fb040593          	addi	a1,s0,-80
    800053ce:	854a                	mv	a0,s2
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	cec080e7          	jalr	-788(ra) # 800040bc <dirlink>
    800053d8:	06054b63          	bltz	a0,8000544e <create+0x154>
  iunlockput(dp);
    800053dc:	854a                	mv	a0,s2
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	84c080e7          	jalr	-1972(ra) # 80003c2a <iunlockput>
  return ip;
    800053e6:	b759                	j	8000536c <create+0x72>
    panic("create: ialloc");
    800053e8:	00003517          	auipc	a0,0x3
    800053ec:	3c050513          	addi	a0,a0,960 # 800087a8 <syscalls+0x2b8>
    800053f0:	ffffb097          	auipc	ra,0xffffb
    800053f4:	14e080e7          	jalr	334(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053f8:	04a95783          	lhu	a5,74(s2)
    800053fc:	2785                	addiw	a5,a5,1
    800053fe:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005402:	854a                	mv	a0,s2
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	4fa080e7          	jalr	1274(ra) # 800038fe <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000540c:	40d0                	lw	a2,4(s1)
    8000540e:	00003597          	auipc	a1,0x3
    80005412:	3aa58593          	addi	a1,a1,938 # 800087b8 <syscalls+0x2c8>
    80005416:	8526                	mv	a0,s1
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	ca4080e7          	jalr	-860(ra) # 800040bc <dirlink>
    80005420:	00054f63          	bltz	a0,8000543e <create+0x144>
    80005424:	00492603          	lw	a2,4(s2)
    80005428:	00003597          	auipc	a1,0x3
    8000542c:	39858593          	addi	a1,a1,920 # 800087c0 <syscalls+0x2d0>
    80005430:	8526                	mv	a0,s1
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	c8a080e7          	jalr	-886(ra) # 800040bc <dirlink>
    8000543a:	f80557e3          	bgez	a0,800053c8 <create+0xce>
      panic("create dots");
    8000543e:	00003517          	auipc	a0,0x3
    80005442:	38a50513          	addi	a0,a0,906 # 800087c8 <syscalls+0x2d8>
    80005446:	ffffb097          	auipc	ra,0xffffb
    8000544a:	0f8080e7          	jalr	248(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000544e:	00003517          	auipc	a0,0x3
    80005452:	38a50513          	addi	a0,a0,906 # 800087d8 <syscalls+0x2e8>
    80005456:	ffffb097          	auipc	ra,0xffffb
    8000545a:	0e8080e7          	jalr	232(ra) # 8000053e <panic>
    return 0;
    8000545e:	84aa                	mv	s1,a0
    80005460:	b731                	j	8000536c <create+0x72>

0000000080005462 <sys_dup>:
{
    80005462:	7179                	addi	sp,sp,-48
    80005464:	f406                	sd	ra,40(sp)
    80005466:	f022                	sd	s0,32(sp)
    80005468:	ec26                	sd	s1,24(sp)
    8000546a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000546c:	fd840613          	addi	a2,s0,-40
    80005470:	4581                	li	a1,0
    80005472:	4501                	li	a0,0
    80005474:	00000097          	auipc	ra,0x0
    80005478:	ddc080e7          	jalr	-548(ra) # 80005250 <argfd>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000547e:	02054363          	bltz	a0,800054a4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005482:	fd843503          	ld	a0,-40(s0)
    80005486:	00000097          	auipc	ra,0x0
    8000548a:	e32080e7          	jalr	-462(ra) # 800052b8 <fdalloc>
    8000548e:	84aa                	mv	s1,a0
    return -1;
    80005490:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005492:	00054963          	bltz	a0,800054a4 <sys_dup+0x42>
  filedup(f);
    80005496:	fd843503          	ld	a0,-40(s0)
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	37a080e7          	jalr	890(ra) # 80004814 <filedup>
  return fd;
    800054a2:	87a6                	mv	a5,s1
}
    800054a4:	853e                	mv	a0,a5
    800054a6:	70a2                	ld	ra,40(sp)
    800054a8:	7402                	ld	s0,32(sp)
    800054aa:	64e2                	ld	s1,24(sp)
    800054ac:	6145                	addi	sp,sp,48
    800054ae:	8082                	ret

00000000800054b0 <sys_read>:
{
    800054b0:	7179                	addi	sp,sp,-48
    800054b2:	f406                	sd	ra,40(sp)
    800054b4:	f022                	sd	s0,32(sp)
    800054b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b8:	fe840613          	addi	a2,s0,-24
    800054bc:	4581                	li	a1,0
    800054be:	4501                	li	a0,0
    800054c0:	00000097          	auipc	ra,0x0
    800054c4:	d90080e7          	jalr	-624(ra) # 80005250 <argfd>
    return -1;
    800054c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ca:	04054163          	bltz	a0,8000550c <sys_read+0x5c>
    800054ce:	fe440593          	addi	a1,s0,-28
    800054d2:	4509                	li	a0,2
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	920080e7          	jalr	-1760(ra) # 80002df4 <argint>
    return -1;
    800054dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054de:	02054763          	bltz	a0,8000550c <sys_read+0x5c>
    800054e2:	fd840593          	addi	a1,s0,-40
    800054e6:	4505                	li	a0,1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	92e080e7          	jalr	-1746(ra) # 80002e16 <argaddr>
    return -1;
    800054f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f2:	00054d63          	bltz	a0,8000550c <sys_read+0x5c>
  return fileread(f, p, n);
    800054f6:	fe442603          	lw	a2,-28(s0)
    800054fa:	fd843583          	ld	a1,-40(s0)
    800054fe:	fe843503          	ld	a0,-24(s0)
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	49e080e7          	jalr	1182(ra) # 800049a0 <fileread>
    8000550a:	87aa                	mv	a5,a0
}
    8000550c:	853e                	mv	a0,a5
    8000550e:	70a2                	ld	ra,40(sp)
    80005510:	7402                	ld	s0,32(sp)
    80005512:	6145                	addi	sp,sp,48
    80005514:	8082                	ret

0000000080005516 <sys_write>:
{
    80005516:	7179                	addi	sp,sp,-48
    80005518:	f406                	sd	ra,40(sp)
    8000551a:	f022                	sd	s0,32(sp)
    8000551c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551e:	fe840613          	addi	a2,s0,-24
    80005522:	4581                	li	a1,0
    80005524:	4501                	li	a0,0
    80005526:	00000097          	auipc	ra,0x0
    8000552a:	d2a080e7          	jalr	-726(ra) # 80005250 <argfd>
    return -1;
    8000552e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005530:	04054163          	bltz	a0,80005572 <sys_write+0x5c>
    80005534:	fe440593          	addi	a1,s0,-28
    80005538:	4509                	li	a0,2
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	8ba080e7          	jalr	-1862(ra) # 80002df4 <argint>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005544:	02054763          	bltz	a0,80005572 <sys_write+0x5c>
    80005548:	fd840593          	addi	a1,s0,-40
    8000554c:	4505                	li	a0,1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	8c8080e7          	jalr	-1848(ra) # 80002e16 <argaddr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005558:	00054d63          	bltz	a0,80005572 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000555c:	fe442603          	lw	a2,-28(s0)
    80005560:	fd843583          	ld	a1,-40(s0)
    80005564:	fe843503          	ld	a0,-24(s0)
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	4fa080e7          	jalr	1274(ra) # 80004a62 <filewrite>
    80005570:	87aa                	mv	a5,a0
}
    80005572:	853e                	mv	a0,a5
    80005574:	70a2                	ld	ra,40(sp)
    80005576:	7402                	ld	s0,32(sp)
    80005578:	6145                	addi	sp,sp,48
    8000557a:	8082                	ret

000000008000557c <sys_close>:
{
    8000557c:	1101                	addi	sp,sp,-32
    8000557e:	ec06                	sd	ra,24(sp)
    80005580:	e822                	sd	s0,16(sp)
    80005582:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005584:	fe040613          	addi	a2,s0,-32
    80005588:	fec40593          	addi	a1,s0,-20
    8000558c:	4501                	li	a0,0
    8000558e:	00000097          	auipc	ra,0x0
    80005592:	cc2080e7          	jalr	-830(ra) # 80005250 <argfd>
    return -1;
    80005596:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005598:	02054463          	bltz	a0,800055c0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	424080e7          	jalr	1060(ra) # 800019c0 <myproc>
    800055a4:	fec42783          	lw	a5,-20(s0)
    800055a8:	07f9                	addi	a5,a5,30
    800055aa:	078e                	slli	a5,a5,0x3
    800055ac:	97aa                	add	a5,a5,a0
    800055ae:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800055b2:	fe043503          	ld	a0,-32(s0)
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	2b0080e7          	jalr	688(ra) # 80004866 <fileclose>
  return 0;
    800055be:	4781                	li	a5,0
}
    800055c0:	853e                	mv	a0,a5
    800055c2:	60e2                	ld	ra,24(sp)
    800055c4:	6442                	ld	s0,16(sp)
    800055c6:	6105                	addi	sp,sp,32
    800055c8:	8082                	ret

00000000800055ca <sys_fstat>:
{
    800055ca:	1101                	addi	sp,sp,-32
    800055cc:	ec06                	sd	ra,24(sp)
    800055ce:	e822                	sd	s0,16(sp)
    800055d0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d2:	fe840613          	addi	a2,s0,-24
    800055d6:	4581                	li	a1,0
    800055d8:	4501                	li	a0,0
    800055da:	00000097          	auipc	ra,0x0
    800055de:	c76080e7          	jalr	-906(ra) # 80005250 <argfd>
    return -1;
    800055e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e4:	02054563          	bltz	a0,8000560e <sys_fstat+0x44>
    800055e8:	fe040593          	addi	a1,s0,-32
    800055ec:	4505                	li	a0,1
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	828080e7          	jalr	-2008(ra) # 80002e16 <argaddr>
    return -1;
    800055f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f8:	00054b63          	bltz	a0,8000560e <sys_fstat+0x44>
  return filestat(f, st);
    800055fc:	fe043583          	ld	a1,-32(s0)
    80005600:	fe843503          	ld	a0,-24(s0)
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	32a080e7          	jalr	810(ra) # 8000492e <filestat>
    8000560c:	87aa                	mv	a5,a0
}
    8000560e:	853e                	mv	a0,a5
    80005610:	60e2                	ld	ra,24(sp)
    80005612:	6442                	ld	s0,16(sp)
    80005614:	6105                	addi	sp,sp,32
    80005616:	8082                	ret

0000000080005618 <sys_link>:
{
    80005618:	7169                	addi	sp,sp,-304
    8000561a:	f606                	sd	ra,296(sp)
    8000561c:	f222                	sd	s0,288(sp)
    8000561e:	ee26                	sd	s1,280(sp)
    80005620:	ea4a                	sd	s2,272(sp)
    80005622:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005624:	08000613          	li	a2,128
    80005628:	ed040593          	addi	a1,s0,-304
    8000562c:	4501                	li	a0,0
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	80a080e7          	jalr	-2038(ra) # 80002e38 <argstr>
    return -1;
    80005636:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005638:	10054e63          	bltz	a0,80005754 <sys_link+0x13c>
    8000563c:	08000613          	li	a2,128
    80005640:	f5040593          	addi	a1,s0,-176
    80005644:	4505                	li	a0,1
    80005646:	ffffd097          	auipc	ra,0xffffd
    8000564a:	7f2080e7          	jalr	2034(ra) # 80002e38 <argstr>
    return -1;
    8000564e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005650:	10054263          	bltz	a0,80005754 <sys_link+0x13c>
  begin_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	d46080e7          	jalr	-698(ra) # 8000439a <begin_op>
  if((ip = namei(old)) == 0){
    8000565c:	ed040513          	addi	a0,s0,-304
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	b1e080e7          	jalr	-1250(ra) # 8000417e <namei>
    80005668:	84aa                	mv	s1,a0
    8000566a:	c551                	beqz	a0,800056f6 <sys_link+0xde>
  ilock(ip);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	35c080e7          	jalr	860(ra) # 800039c8 <ilock>
  if(ip->type == T_DIR){
    80005674:	04449703          	lh	a4,68(s1)
    80005678:	4785                	li	a5,1
    8000567a:	08f70463          	beq	a4,a5,80005702 <sys_link+0xea>
  ip->nlink++;
    8000567e:	04a4d783          	lhu	a5,74(s1)
    80005682:	2785                	addiw	a5,a5,1
    80005684:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	274080e7          	jalr	628(ra) # 800038fe <iupdate>
  iunlock(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	3f6080e7          	jalr	1014(ra) # 80003a8a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000569c:	fd040593          	addi	a1,s0,-48
    800056a0:	f5040513          	addi	a0,s0,-176
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	af8080e7          	jalr	-1288(ra) # 8000419c <nameiparent>
    800056ac:	892a                	mv	s2,a0
    800056ae:	c935                	beqz	a0,80005722 <sys_link+0x10a>
  ilock(dp);
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	318080e7          	jalr	792(ra) # 800039c8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056b8:	00092703          	lw	a4,0(s2)
    800056bc:	409c                	lw	a5,0(s1)
    800056be:	04f71d63          	bne	a4,a5,80005718 <sys_link+0x100>
    800056c2:	40d0                	lw	a2,4(s1)
    800056c4:	fd040593          	addi	a1,s0,-48
    800056c8:	854a                	mv	a0,s2
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	9f2080e7          	jalr	-1550(ra) # 800040bc <dirlink>
    800056d2:	04054363          	bltz	a0,80005718 <sys_link+0x100>
  iunlockput(dp);
    800056d6:	854a                	mv	a0,s2
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	552080e7          	jalr	1362(ra) # 80003c2a <iunlockput>
  iput(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	4a0080e7          	jalr	1184(ra) # 80003b82 <iput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	d30080e7          	jalr	-720(ra) # 8000441a <end_op>
  return 0;
    800056f2:	4781                	li	a5,0
    800056f4:	a085                	j	80005754 <sys_link+0x13c>
    end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	d24080e7          	jalr	-732(ra) # 8000441a <end_op>
    return -1;
    800056fe:	57fd                	li	a5,-1
    80005700:	a891                	j	80005754 <sys_link+0x13c>
    iunlockput(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	526080e7          	jalr	1318(ra) # 80003c2a <iunlockput>
    end_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	d0e080e7          	jalr	-754(ra) # 8000441a <end_op>
    return -1;
    80005714:	57fd                	li	a5,-1
    80005716:	a83d                	j	80005754 <sys_link+0x13c>
    iunlockput(dp);
    80005718:	854a                	mv	a0,s2
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	510080e7          	jalr	1296(ra) # 80003c2a <iunlockput>
  ilock(ip);
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	2a4080e7          	jalr	676(ra) # 800039c8 <ilock>
  ip->nlink--;
    8000572c:	04a4d783          	lhu	a5,74(s1)
    80005730:	37fd                	addiw	a5,a5,-1
    80005732:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	1c6080e7          	jalr	454(ra) # 800038fe <iupdate>
  iunlockput(ip);
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	4e8080e7          	jalr	1256(ra) # 80003c2a <iunlockput>
  end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	cd0080e7          	jalr	-816(ra) # 8000441a <end_op>
  return -1;
    80005752:	57fd                	li	a5,-1
}
    80005754:	853e                	mv	a0,a5
    80005756:	70b2                	ld	ra,296(sp)
    80005758:	7412                	ld	s0,288(sp)
    8000575a:	64f2                	ld	s1,280(sp)
    8000575c:	6952                	ld	s2,272(sp)
    8000575e:	6155                	addi	sp,sp,304
    80005760:	8082                	ret

0000000080005762 <sys_unlink>:
{
    80005762:	7151                	addi	sp,sp,-240
    80005764:	f586                	sd	ra,232(sp)
    80005766:	f1a2                	sd	s0,224(sp)
    80005768:	eda6                	sd	s1,216(sp)
    8000576a:	e9ca                	sd	s2,208(sp)
    8000576c:	e5ce                	sd	s3,200(sp)
    8000576e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005770:	08000613          	li	a2,128
    80005774:	f3040593          	addi	a1,s0,-208
    80005778:	4501                	li	a0,0
    8000577a:	ffffd097          	auipc	ra,0xffffd
    8000577e:	6be080e7          	jalr	1726(ra) # 80002e38 <argstr>
    80005782:	18054163          	bltz	a0,80005904 <sys_unlink+0x1a2>
  begin_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	c14080e7          	jalr	-1004(ra) # 8000439a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000578e:	fb040593          	addi	a1,s0,-80
    80005792:	f3040513          	addi	a0,s0,-208
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	a06080e7          	jalr	-1530(ra) # 8000419c <nameiparent>
    8000579e:	84aa                	mv	s1,a0
    800057a0:	c979                	beqz	a0,80005876 <sys_unlink+0x114>
  ilock(dp);
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	226080e7          	jalr	550(ra) # 800039c8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057aa:	00003597          	auipc	a1,0x3
    800057ae:	00e58593          	addi	a1,a1,14 # 800087b8 <syscalls+0x2c8>
    800057b2:	fb040513          	addi	a0,s0,-80
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	6dc080e7          	jalr	1756(ra) # 80003e92 <namecmp>
    800057be:	14050a63          	beqz	a0,80005912 <sys_unlink+0x1b0>
    800057c2:	00003597          	auipc	a1,0x3
    800057c6:	ffe58593          	addi	a1,a1,-2 # 800087c0 <syscalls+0x2d0>
    800057ca:	fb040513          	addi	a0,s0,-80
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	6c4080e7          	jalr	1732(ra) # 80003e92 <namecmp>
    800057d6:	12050e63          	beqz	a0,80005912 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057da:	f2c40613          	addi	a2,s0,-212
    800057de:	fb040593          	addi	a1,s0,-80
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	6c8080e7          	jalr	1736(ra) # 80003eac <dirlookup>
    800057ec:	892a                	mv	s2,a0
    800057ee:	12050263          	beqz	a0,80005912 <sys_unlink+0x1b0>
  ilock(ip);
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	1d6080e7          	jalr	470(ra) # 800039c8 <ilock>
  if(ip->nlink < 1)
    800057fa:	04a91783          	lh	a5,74(s2)
    800057fe:	08f05263          	blez	a5,80005882 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005802:	04491703          	lh	a4,68(s2)
    80005806:	4785                	li	a5,1
    80005808:	08f70563          	beq	a4,a5,80005892 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000580c:	4641                	li	a2,16
    8000580e:	4581                	li	a1,0
    80005810:	fc040513          	addi	a0,s0,-64
    80005814:	ffffb097          	auipc	ra,0xffffb
    80005818:	4cc080e7          	jalr	1228(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000581c:	4741                	li	a4,16
    8000581e:	f2c42683          	lw	a3,-212(s0)
    80005822:	fc040613          	addi	a2,s0,-64
    80005826:	4581                	li	a1,0
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	54a080e7          	jalr	1354(ra) # 80003d74 <writei>
    80005832:	47c1                	li	a5,16
    80005834:	0af51563          	bne	a0,a5,800058de <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005838:	04491703          	lh	a4,68(s2)
    8000583c:	4785                	li	a5,1
    8000583e:	0af70863          	beq	a4,a5,800058ee <sys_unlink+0x18c>
  iunlockput(dp);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	3e6080e7          	jalr	998(ra) # 80003c2a <iunlockput>
  ip->nlink--;
    8000584c:	04a95783          	lhu	a5,74(s2)
    80005850:	37fd                	addiw	a5,a5,-1
    80005852:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005856:	854a                	mv	a0,s2
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	0a6080e7          	jalr	166(ra) # 800038fe <iupdate>
  iunlockput(ip);
    80005860:	854a                	mv	a0,s2
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	3c8080e7          	jalr	968(ra) # 80003c2a <iunlockput>
  end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	bb0080e7          	jalr	-1104(ra) # 8000441a <end_op>
  return 0;
    80005872:	4501                	li	a0,0
    80005874:	a84d                	j	80005926 <sys_unlink+0x1c4>
    end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	ba4080e7          	jalr	-1116(ra) # 8000441a <end_op>
    return -1;
    8000587e:	557d                	li	a0,-1
    80005880:	a05d                	j	80005926 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005882:	00003517          	auipc	a0,0x3
    80005886:	f6650513          	addi	a0,a0,-154 # 800087e8 <syscalls+0x2f8>
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005892:	04c92703          	lw	a4,76(s2)
    80005896:	02000793          	li	a5,32
    8000589a:	f6e7f9e3          	bgeu	a5,a4,8000580c <sys_unlink+0xaa>
    8000589e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a2:	4741                	li	a4,16
    800058a4:	86ce                	mv	a3,s3
    800058a6:	f1840613          	addi	a2,s0,-232
    800058aa:	4581                	li	a1,0
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	3ce080e7          	jalr	974(ra) # 80003c7c <readi>
    800058b6:	47c1                	li	a5,16
    800058b8:	00f51b63          	bne	a0,a5,800058ce <sys_unlink+0x16c>
    if(de.inum != 0)
    800058bc:	f1845783          	lhu	a5,-232(s0)
    800058c0:	e7a1                	bnez	a5,80005908 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c2:	29c1                	addiw	s3,s3,16
    800058c4:	04c92783          	lw	a5,76(s2)
    800058c8:	fcf9ede3          	bltu	s3,a5,800058a2 <sys_unlink+0x140>
    800058cc:	b781                	j	8000580c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058ce:	00003517          	auipc	a0,0x3
    800058d2:	f3250513          	addi	a0,a0,-206 # 80008800 <syscalls+0x310>
    800058d6:	ffffb097          	auipc	ra,0xffffb
    800058da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>
    panic("unlink: writei");
    800058de:	00003517          	auipc	a0,0x3
    800058e2:	f3a50513          	addi	a0,a0,-198 # 80008818 <syscalls+0x328>
    800058e6:	ffffb097          	auipc	ra,0xffffb
    800058ea:	c58080e7          	jalr	-936(ra) # 8000053e <panic>
    dp->nlink--;
    800058ee:	04a4d783          	lhu	a5,74(s1)
    800058f2:	37fd                	addiw	a5,a5,-1
    800058f4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	004080e7          	jalr	4(ra) # 800038fe <iupdate>
    80005902:	b781                	j	80005842 <sys_unlink+0xe0>
    return -1;
    80005904:	557d                	li	a0,-1
    80005906:	a005                	j	80005926 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005908:	854a                	mv	a0,s2
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	320080e7          	jalr	800(ra) # 80003c2a <iunlockput>
  iunlockput(dp);
    80005912:	8526                	mv	a0,s1
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	316080e7          	jalr	790(ra) # 80003c2a <iunlockput>
  end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	afe080e7          	jalr	-1282(ra) # 8000441a <end_op>
  return -1;
    80005924:	557d                	li	a0,-1
}
    80005926:	70ae                	ld	ra,232(sp)
    80005928:	740e                	ld	s0,224(sp)
    8000592a:	64ee                	ld	s1,216(sp)
    8000592c:	694e                	ld	s2,208(sp)
    8000592e:	69ae                	ld	s3,200(sp)
    80005930:	616d                	addi	sp,sp,240
    80005932:	8082                	ret

0000000080005934 <sys_open>:

uint64
sys_open(void)
{
    80005934:	7131                	addi	sp,sp,-192
    80005936:	fd06                	sd	ra,184(sp)
    80005938:	f922                	sd	s0,176(sp)
    8000593a:	f526                	sd	s1,168(sp)
    8000593c:	f14a                	sd	s2,160(sp)
    8000593e:	ed4e                	sd	s3,152(sp)
    80005940:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005942:	08000613          	li	a2,128
    80005946:	f5040593          	addi	a1,s0,-176
    8000594a:	4501                	li	a0,0
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	4ec080e7          	jalr	1260(ra) # 80002e38 <argstr>
    return -1;
    80005954:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005956:	0c054163          	bltz	a0,80005a18 <sys_open+0xe4>
    8000595a:	f4c40593          	addi	a1,s0,-180
    8000595e:	4505                	li	a0,1
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	494080e7          	jalr	1172(ra) # 80002df4 <argint>
    80005968:	0a054863          	bltz	a0,80005a18 <sys_open+0xe4>

  begin_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	a2e080e7          	jalr	-1490(ra) # 8000439a <begin_op>

  if(omode & O_CREATE){
    80005974:	f4c42783          	lw	a5,-180(s0)
    80005978:	2007f793          	andi	a5,a5,512
    8000597c:	cbdd                	beqz	a5,80005a32 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000597e:	4681                	li	a3,0
    80005980:	4601                	li	a2,0
    80005982:	4589                	li	a1,2
    80005984:	f5040513          	addi	a0,s0,-176
    80005988:	00000097          	auipc	ra,0x0
    8000598c:	972080e7          	jalr	-1678(ra) # 800052fa <create>
    80005990:	892a                	mv	s2,a0
    if(ip == 0){
    80005992:	c959                	beqz	a0,80005a28 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005994:	04491703          	lh	a4,68(s2)
    80005998:	478d                	li	a5,3
    8000599a:	00f71763          	bne	a4,a5,800059a8 <sys_open+0x74>
    8000599e:	04695703          	lhu	a4,70(s2)
    800059a2:	47a5                	li	a5,9
    800059a4:	0ce7ec63          	bltu	a5,a4,80005a7c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	e02080e7          	jalr	-510(ra) # 800047aa <filealloc>
    800059b0:	89aa                	mv	s3,a0
    800059b2:	10050263          	beqz	a0,80005ab6 <sys_open+0x182>
    800059b6:	00000097          	auipc	ra,0x0
    800059ba:	902080e7          	jalr	-1790(ra) # 800052b8 <fdalloc>
    800059be:	84aa                	mv	s1,a0
    800059c0:	0e054663          	bltz	a0,80005aac <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059c4:	04491703          	lh	a4,68(s2)
    800059c8:	478d                	li	a5,3
    800059ca:	0cf70463          	beq	a4,a5,80005a92 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059ce:	4789                	li	a5,2
    800059d0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059d4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059d8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059dc:	f4c42783          	lw	a5,-180(s0)
    800059e0:	0017c713          	xori	a4,a5,1
    800059e4:	8b05                	andi	a4,a4,1
    800059e6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059ea:	0037f713          	andi	a4,a5,3
    800059ee:	00e03733          	snez	a4,a4
    800059f2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059f6:	4007f793          	andi	a5,a5,1024
    800059fa:	c791                	beqz	a5,80005a06 <sys_open+0xd2>
    800059fc:	04491703          	lh	a4,68(s2)
    80005a00:	4789                	li	a5,2
    80005a02:	08f70f63          	beq	a4,a5,80005aa0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a06:	854a                	mv	a0,s2
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	082080e7          	jalr	130(ra) # 80003a8a <iunlock>
  end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	a0a080e7          	jalr	-1526(ra) # 8000441a <end_op>

  return fd;
}
    80005a18:	8526                	mv	a0,s1
    80005a1a:	70ea                	ld	ra,184(sp)
    80005a1c:	744a                	ld	s0,176(sp)
    80005a1e:	74aa                	ld	s1,168(sp)
    80005a20:	790a                	ld	s2,160(sp)
    80005a22:	69ea                	ld	s3,152(sp)
    80005a24:	6129                	addi	sp,sp,192
    80005a26:	8082                	ret
      end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	9f2080e7          	jalr	-1550(ra) # 8000441a <end_op>
      return -1;
    80005a30:	b7e5                	j	80005a18 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a32:	f5040513          	addi	a0,s0,-176
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	748080e7          	jalr	1864(ra) # 8000417e <namei>
    80005a3e:	892a                	mv	s2,a0
    80005a40:	c905                	beqz	a0,80005a70 <sys_open+0x13c>
    ilock(ip);
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	f86080e7          	jalr	-122(ra) # 800039c8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a4a:	04491703          	lh	a4,68(s2)
    80005a4e:	4785                	li	a5,1
    80005a50:	f4f712e3          	bne	a4,a5,80005994 <sys_open+0x60>
    80005a54:	f4c42783          	lw	a5,-180(s0)
    80005a58:	dba1                	beqz	a5,800059a8 <sys_open+0x74>
      iunlockput(ip);
    80005a5a:	854a                	mv	a0,s2
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	1ce080e7          	jalr	462(ra) # 80003c2a <iunlockput>
      end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	9b6080e7          	jalr	-1610(ra) # 8000441a <end_op>
      return -1;
    80005a6c:	54fd                	li	s1,-1
    80005a6e:	b76d                	j	80005a18 <sys_open+0xe4>
      end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	9aa080e7          	jalr	-1622(ra) # 8000441a <end_op>
      return -1;
    80005a78:	54fd                	li	s1,-1
    80005a7a:	bf79                	j	80005a18 <sys_open+0xe4>
    iunlockput(ip);
    80005a7c:	854a                	mv	a0,s2
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	1ac080e7          	jalr	428(ra) # 80003c2a <iunlockput>
    end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	994080e7          	jalr	-1644(ra) # 8000441a <end_op>
    return -1;
    80005a8e:	54fd                	li	s1,-1
    80005a90:	b761                	j	80005a18 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a92:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a96:	04691783          	lh	a5,70(s2)
    80005a9a:	02f99223          	sh	a5,36(s3)
    80005a9e:	bf2d                	j	800059d8 <sys_open+0xa4>
    itrunc(ip);
    80005aa0:	854a                	mv	a0,s2
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	034080e7          	jalr	52(ra) # 80003ad6 <itrunc>
    80005aaa:	bfb1                	j	80005a06 <sys_open+0xd2>
      fileclose(f);
    80005aac:	854e                	mv	a0,s3
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	db8080e7          	jalr	-584(ra) # 80004866 <fileclose>
    iunlockput(ip);
    80005ab6:	854a                	mv	a0,s2
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	172080e7          	jalr	370(ra) # 80003c2a <iunlockput>
    end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	95a080e7          	jalr	-1702(ra) # 8000441a <end_op>
    return -1;
    80005ac8:	54fd                	li	s1,-1
    80005aca:	b7b9                	j	80005a18 <sys_open+0xe4>

0000000080005acc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005acc:	7175                	addi	sp,sp,-144
    80005ace:	e506                	sd	ra,136(sp)
    80005ad0:	e122                	sd	s0,128(sp)
    80005ad2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	8c6080e7          	jalr	-1850(ra) # 8000439a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005adc:	08000613          	li	a2,128
    80005ae0:	f7040593          	addi	a1,s0,-144
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	352080e7          	jalr	850(ra) # 80002e38 <argstr>
    80005aee:	02054963          	bltz	a0,80005b20 <sys_mkdir+0x54>
    80005af2:	4681                	li	a3,0
    80005af4:	4601                	li	a2,0
    80005af6:	4585                	li	a1,1
    80005af8:	f7040513          	addi	a0,s0,-144
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	7fe080e7          	jalr	2046(ra) # 800052fa <create>
    80005b04:	cd11                	beqz	a0,80005b20 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	124080e7          	jalr	292(ra) # 80003c2a <iunlockput>
  end_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	90c080e7          	jalr	-1780(ra) # 8000441a <end_op>
  return 0;
    80005b16:	4501                	li	a0,0
}
    80005b18:	60aa                	ld	ra,136(sp)
    80005b1a:	640a                	ld	s0,128(sp)
    80005b1c:	6149                	addi	sp,sp,144
    80005b1e:	8082                	ret
    end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	8fa080e7          	jalr	-1798(ra) # 8000441a <end_op>
    return -1;
    80005b28:	557d                	li	a0,-1
    80005b2a:	b7fd                	j	80005b18 <sys_mkdir+0x4c>

0000000080005b2c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b2c:	7135                	addi	sp,sp,-160
    80005b2e:	ed06                	sd	ra,152(sp)
    80005b30:	e922                	sd	s0,144(sp)
    80005b32:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	866080e7          	jalr	-1946(ra) # 8000439a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b3c:	08000613          	li	a2,128
    80005b40:	f7040593          	addi	a1,s0,-144
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	2f2080e7          	jalr	754(ra) # 80002e38 <argstr>
    80005b4e:	04054a63          	bltz	a0,80005ba2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b52:	f6c40593          	addi	a1,s0,-148
    80005b56:	4505                	li	a0,1
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	29c080e7          	jalr	668(ra) # 80002df4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b60:	04054163          	bltz	a0,80005ba2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b64:	f6840593          	addi	a1,s0,-152
    80005b68:	4509                	li	a0,2
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	28a080e7          	jalr	650(ra) # 80002df4 <argint>
     argint(1, &major) < 0 ||
    80005b72:	02054863          	bltz	a0,80005ba2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b76:	f6841683          	lh	a3,-152(s0)
    80005b7a:	f6c41603          	lh	a2,-148(s0)
    80005b7e:	458d                	li	a1,3
    80005b80:	f7040513          	addi	a0,s0,-144
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	776080e7          	jalr	1910(ra) # 800052fa <create>
     argint(2, &minor) < 0 ||
    80005b8c:	c919                	beqz	a0,80005ba2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	09c080e7          	jalr	156(ra) # 80003c2a <iunlockput>
  end_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	884080e7          	jalr	-1916(ra) # 8000441a <end_op>
  return 0;
    80005b9e:	4501                	li	a0,0
    80005ba0:	a031                	j	80005bac <sys_mknod+0x80>
    end_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	878080e7          	jalr	-1928(ra) # 8000441a <end_op>
    return -1;
    80005baa:	557d                	li	a0,-1
}
    80005bac:	60ea                	ld	ra,152(sp)
    80005bae:	644a                	ld	s0,144(sp)
    80005bb0:	610d                	addi	sp,sp,160
    80005bb2:	8082                	ret

0000000080005bb4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bb4:	7135                	addi	sp,sp,-160
    80005bb6:	ed06                	sd	ra,152(sp)
    80005bb8:	e922                	sd	s0,144(sp)
    80005bba:	e526                	sd	s1,136(sp)
    80005bbc:	e14a                	sd	s2,128(sp)
    80005bbe:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	e00080e7          	jalr	-512(ra) # 800019c0 <myproc>
    80005bc8:	892a                	mv	s2,a0
  
  begin_op();
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	7d0080e7          	jalr	2000(ra) # 8000439a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bd2:	08000613          	li	a2,128
    80005bd6:	f6040593          	addi	a1,s0,-160
    80005bda:	4501                	li	a0,0
    80005bdc:	ffffd097          	auipc	ra,0xffffd
    80005be0:	25c080e7          	jalr	604(ra) # 80002e38 <argstr>
    80005be4:	04054b63          	bltz	a0,80005c3a <sys_chdir+0x86>
    80005be8:	f6040513          	addi	a0,s0,-160
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	592080e7          	jalr	1426(ra) # 8000417e <namei>
    80005bf4:	84aa                	mv	s1,a0
    80005bf6:	c131                	beqz	a0,80005c3a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	dd0080e7          	jalr	-560(ra) # 800039c8 <ilock>
  if(ip->type != T_DIR){
    80005c00:	04449703          	lh	a4,68(s1)
    80005c04:	4785                	li	a5,1
    80005c06:	04f71063          	bne	a4,a5,80005c46 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c0a:	8526                	mv	a0,s1
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	e7e080e7          	jalr	-386(ra) # 80003a8a <iunlock>
  iput(p->cwd);
    80005c14:	17893503          	ld	a0,376(s2)
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	f6a080e7          	jalr	-150(ra) # 80003b82 <iput>
  end_op();
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	7fa080e7          	jalr	2042(ra) # 8000441a <end_op>
  p->cwd = ip;
    80005c28:	16993c23          	sd	s1,376(s2)
  return 0;
    80005c2c:	4501                	li	a0,0
}
    80005c2e:	60ea                	ld	ra,152(sp)
    80005c30:	644a                	ld	s0,144(sp)
    80005c32:	64aa                	ld	s1,136(sp)
    80005c34:	690a                	ld	s2,128(sp)
    80005c36:	610d                	addi	sp,sp,160
    80005c38:	8082                	ret
    end_op();
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	7e0080e7          	jalr	2016(ra) # 8000441a <end_op>
    return -1;
    80005c42:	557d                	li	a0,-1
    80005c44:	b7ed                	j	80005c2e <sys_chdir+0x7a>
    iunlockput(ip);
    80005c46:	8526                	mv	a0,s1
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	fe2080e7          	jalr	-30(ra) # 80003c2a <iunlockput>
    end_op();
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	7ca080e7          	jalr	1994(ra) # 8000441a <end_op>
    return -1;
    80005c58:	557d                	li	a0,-1
    80005c5a:	bfd1                	j	80005c2e <sys_chdir+0x7a>

0000000080005c5c <sys_exec>:

uint64
sys_exec(void)
{
    80005c5c:	7145                	addi	sp,sp,-464
    80005c5e:	e786                	sd	ra,456(sp)
    80005c60:	e3a2                	sd	s0,448(sp)
    80005c62:	ff26                	sd	s1,440(sp)
    80005c64:	fb4a                	sd	s2,432(sp)
    80005c66:	f74e                	sd	s3,424(sp)
    80005c68:	f352                	sd	s4,416(sp)
    80005c6a:	ef56                	sd	s5,408(sp)
    80005c6c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c6e:	08000613          	li	a2,128
    80005c72:	f4040593          	addi	a1,s0,-192
    80005c76:	4501                	li	a0,0
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	1c0080e7          	jalr	448(ra) # 80002e38 <argstr>
    return -1;
    80005c80:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c82:	0c054a63          	bltz	a0,80005d56 <sys_exec+0xfa>
    80005c86:	e3840593          	addi	a1,s0,-456
    80005c8a:	4505                	li	a0,1
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	18a080e7          	jalr	394(ra) # 80002e16 <argaddr>
    80005c94:	0c054163          	bltz	a0,80005d56 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c98:	10000613          	li	a2,256
    80005c9c:	4581                	li	a1,0
    80005c9e:	e4040513          	addi	a0,s0,-448
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	03e080e7          	jalr	62(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005caa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cae:	89a6                	mv	s3,s1
    80005cb0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cb2:	02000a13          	li	s4,32
    80005cb6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cba:	00391513          	slli	a0,s2,0x3
    80005cbe:	e3040593          	addi	a1,s0,-464
    80005cc2:	e3843783          	ld	a5,-456(s0)
    80005cc6:	953e                	add	a0,a0,a5
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	092080e7          	jalr	146(ra) # 80002d5a <fetchaddr>
    80005cd0:	02054a63          	bltz	a0,80005d04 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cd4:	e3043783          	ld	a5,-464(s0)
    80005cd8:	c3b9                	beqz	a5,80005d1e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cda:	ffffb097          	auipc	ra,0xffffb
    80005cde:	e1a080e7          	jalr	-486(ra) # 80000af4 <kalloc>
    80005ce2:	85aa                	mv	a1,a0
    80005ce4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ce8:	cd11                	beqz	a0,80005d04 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cea:	6605                	lui	a2,0x1
    80005cec:	e3043503          	ld	a0,-464(s0)
    80005cf0:	ffffd097          	auipc	ra,0xffffd
    80005cf4:	0bc080e7          	jalr	188(ra) # 80002dac <fetchstr>
    80005cf8:	00054663          	bltz	a0,80005d04 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cfc:	0905                	addi	s2,s2,1
    80005cfe:	09a1                	addi	s3,s3,8
    80005d00:	fb491be3          	bne	s2,s4,80005cb6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d04:	10048913          	addi	s2,s1,256
    80005d08:	6088                	ld	a0,0(s1)
    80005d0a:	c529                	beqz	a0,80005d54 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d0c:	ffffb097          	auipc	ra,0xffffb
    80005d10:	cec080e7          	jalr	-788(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d14:	04a1                	addi	s1,s1,8
    80005d16:	ff2499e3          	bne	s1,s2,80005d08 <sys_exec+0xac>
  return -1;
    80005d1a:	597d                	li	s2,-1
    80005d1c:	a82d                	j	80005d56 <sys_exec+0xfa>
      argv[i] = 0;
    80005d1e:	0a8e                	slli	s5,s5,0x3
    80005d20:	fc040793          	addi	a5,s0,-64
    80005d24:	9abe                	add	s5,s5,a5
    80005d26:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d2a:	e4040593          	addi	a1,s0,-448
    80005d2e:	f4040513          	addi	a0,s0,-192
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	194080e7          	jalr	404(ra) # 80004ec6 <exec>
    80005d3a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d3c:	10048993          	addi	s3,s1,256
    80005d40:	6088                	ld	a0,0(s1)
    80005d42:	c911                	beqz	a0,80005d56 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d44:	ffffb097          	auipc	ra,0xffffb
    80005d48:	cb4080e7          	jalr	-844(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d4c:	04a1                	addi	s1,s1,8
    80005d4e:	ff3499e3          	bne	s1,s3,80005d40 <sys_exec+0xe4>
    80005d52:	a011                	j	80005d56 <sys_exec+0xfa>
  return -1;
    80005d54:	597d                	li	s2,-1
}
    80005d56:	854a                	mv	a0,s2
    80005d58:	60be                	ld	ra,456(sp)
    80005d5a:	641e                	ld	s0,448(sp)
    80005d5c:	74fa                	ld	s1,440(sp)
    80005d5e:	795a                	ld	s2,432(sp)
    80005d60:	79ba                	ld	s3,424(sp)
    80005d62:	7a1a                	ld	s4,416(sp)
    80005d64:	6afa                	ld	s5,408(sp)
    80005d66:	6179                	addi	sp,sp,464
    80005d68:	8082                	ret

0000000080005d6a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d6a:	7139                	addi	sp,sp,-64
    80005d6c:	fc06                	sd	ra,56(sp)
    80005d6e:	f822                	sd	s0,48(sp)
    80005d70:	f426                	sd	s1,40(sp)
    80005d72:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d74:	ffffc097          	auipc	ra,0xffffc
    80005d78:	c4c080e7          	jalr	-948(ra) # 800019c0 <myproc>
    80005d7c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d7e:	fd840593          	addi	a1,s0,-40
    80005d82:	4501                	li	a0,0
    80005d84:	ffffd097          	auipc	ra,0xffffd
    80005d88:	092080e7          	jalr	146(ra) # 80002e16 <argaddr>
    return -1;
    80005d8c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d8e:	0e054063          	bltz	a0,80005e6e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d92:	fc840593          	addi	a1,s0,-56
    80005d96:	fd040513          	addi	a0,s0,-48
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	dfc080e7          	jalr	-516(ra) # 80004b96 <pipealloc>
    return -1;
    80005da2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005da4:	0c054563          	bltz	a0,80005e6e <sys_pipe+0x104>
  fd0 = -1;
    80005da8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dac:	fd043503          	ld	a0,-48(s0)
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	508080e7          	jalr	1288(ra) # 800052b8 <fdalloc>
    80005db8:	fca42223          	sw	a0,-60(s0)
    80005dbc:	08054c63          	bltz	a0,80005e54 <sys_pipe+0xea>
    80005dc0:	fc843503          	ld	a0,-56(s0)
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	4f4080e7          	jalr	1268(ra) # 800052b8 <fdalloc>
    80005dcc:	fca42023          	sw	a0,-64(s0)
    80005dd0:	06054863          	bltz	a0,80005e40 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dd4:	4691                	li	a3,4
    80005dd6:	fc440613          	addi	a2,s0,-60
    80005dda:	fd843583          	ld	a1,-40(s0)
    80005dde:	7ca8                	ld	a0,120(s1)
    80005de0:	ffffc097          	auipc	ra,0xffffc
    80005de4:	892080e7          	jalr	-1902(ra) # 80001672 <copyout>
    80005de8:	02054063          	bltz	a0,80005e08 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dec:	4691                	li	a3,4
    80005dee:	fc040613          	addi	a2,s0,-64
    80005df2:	fd843583          	ld	a1,-40(s0)
    80005df6:	0591                	addi	a1,a1,4
    80005df8:	7ca8                	ld	a0,120(s1)
    80005dfa:	ffffc097          	auipc	ra,0xffffc
    80005dfe:	878080e7          	jalr	-1928(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e02:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e04:	06055563          	bgez	a0,80005e6e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e08:	fc442783          	lw	a5,-60(s0)
    80005e0c:	07f9                	addi	a5,a5,30
    80005e0e:	078e                	slli	a5,a5,0x3
    80005e10:	97a6                	add	a5,a5,s1
    80005e12:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e16:	fc042503          	lw	a0,-64(s0)
    80005e1a:	0579                	addi	a0,a0,30
    80005e1c:	050e                	slli	a0,a0,0x3
    80005e1e:	9526                	add	a0,a0,s1
    80005e20:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e24:	fd043503          	ld	a0,-48(s0)
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	a3e080e7          	jalr	-1474(ra) # 80004866 <fileclose>
    fileclose(wf);
    80005e30:	fc843503          	ld	a0,-56(s0)
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	a32080e7          	jalr	-1486(ra) # 80004866 <fileclose>
    return -1;
    80005e3c:	57fd                	li	a5,-1
    80005e3e:	a805                	j	80005e6e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e40:	fc442783          	lw	a5,-60(s0)
    80005e44:	0007c863          	bltz	a5,80005e54 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e48:	01e78513          	addi	a0,a5,30
    80005e4c:	050e                	slli	a0,a0,0x3
    80005e4e:	9526                	add	a0,a0,s1
    80005e50:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e54:	fd043503          	ld	a0,-48(s0)
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	a0e080e7          	jalr	-1522(ra) # 80004866 <fileclose>
    fileclose(wf);
    80005e60:	fc843503          	ld	a0,-56(s0)
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	a02080e7          	jalr	-1534(ra) # 80004866 <fileclose>
    return -1;
    80005e6c:	57fd                	li	a5,-1
}
    80005e6e:	853e                	mv	a0,a5
    80005e70:	70e2                	ld	ra,56(sp)
    80005e72:	7442                	ld	s0,48(sp)
    80005e74:	74a2                	ld	s1,40(sp)
    80005e76:	6121                	addi	sp,sp,64
    80005e78:	8082                	ret
    80005e7a:	0000                	unimp
    80005e7c:	0000                	unimp
	...

0000000080005e80 <kernelvec>:
    80005e80:	7111                	addi	sp,sp,-256
    80005e82:	e006                	sd	ra,0(sp)
    80005e84:	e40a                	sd	sp,8(sp)
    80005e86:	e80e                	sd	gp,16(sp)
    80005e88:	ec12                	sd	tp,24(sp)
    80005e8a:	f016                	sd	t0,32(sp)
    80005e8c:	f41a                	sd	t1,40(sp)
    80005e8e:	f81e                	sd	t2,48(sp)
    80005e90:	fc22                	sd	s0,56(sp)
    80005e92:	e0a6                	sd	s1,64(sp)
    80005e94:	e4aa                	sd	a0,72(sp)
    80005e96:	e8ae                	sd	a1,80(sp)
    80005e98:	ecb2                	sd	a2,88(sp)
    80005e9a:	f0b6                	sd	a3,96(sp)
    80005e9c:	f4ba                	sd	a4,104(sp)
    80005e9e:	f8be                	sd	a5,112(sp)
    80005ea0:	fcc2                	sd	a6,120(sp)
    80005ea2:	e146                	sd	a7,128(sp)
    80005ea4:	e54a                	sd	s2,136(sp)
    80005ea6:	e94e                	sd	s3,144(sp)
    80005ea8:	ed52                	sd	s4,152(sp)
    80005eaa:	f156                	sd	s5,160(sp)
    80005eac:	f55a                	sd	s6,168(sp)
    80005eae:	f95e                	sd	s7,176(sp)
    80005eb0:	fd62                	sd	s8,184(sp)
    80005eb2:	e1e6                	sd	s9,192(sp)
    80005eb4:	e5ea                	sd	s10,200(sp)
    80005eb6:	e9ee                	sd	s11,208(sp)
    80005eb8:	edf2                	sd	t3,216(sp)
    80005eba:	f1f6                	sd	t4,224(sp)
    80005ebc:	f5fa                	sd	t5,232(sp)
    80005ebe:	f9fe                	sd	t6,240(sp)
    80005ec0:	d67fc0ef          	jal	ra,80002c26 <kerneltrap>
    80005ec4:	6082                	ld	ra,0(sp)
    80005ec6:	6122                	ld	sp,8(sp)
    80005ec8:	61c2                	ld	gp,16(sp)
    80005eca:	7282                	ld	t0,32(sp)
    80005ecc:	7322                	ld	t1,40(sp)
    80005ece:	73c2                	ld	t2,48(sp)
    80005ed0:	7462                	ld	s0,56(sp)
    80005ed2:	6486                	ld	s1,64(sp)
    80005ed4:	6526                	ld	a0,72(sp)
    80005ed6:	65c6                	ld	a1,80(sp)
    80005ed8:	6666                	ld	a2,88(sp)
    80005eda:	7686                	ld	a3,96(sp)
    80005edc:	7726                	ld	a4,104(sp)
    80005ede:	77c6                	ld	a5,112(sp)
    80005ee0:	7866                	ld	a6,120(sp)
    80005ee2:	688a                	ld	a7,128(sp)
    80005ee4:	692a                	ld	s2,136(sp)
    80005ee6:	69ca                	ld	s3,144(sp)
    80005ee8:	6a6a                	ld	s4,152(sp)
    80005eea:	7a8a                	ld	s5,160(sp)
    80005eec:	7b2a                	ld	s6,168(sp)
    80005eee:	7bca                	ld	s7,176(sp)
    80005ef0:	7c6a                	ld	s8,184(sp)
    80005ef2:	6c8e                	ld	s9,192(sp)
    80005ef4:	6d2e                	ld	s10,200(sp)
    80005ef6:	6dce                	ld	s11,208(sp)
    80005ef8:	6e6e                	ld	t3,216(sp)
    80005efa:	7e8e                	ld	t4,224(sp)
    80005efc:	7f2e                	ld	t5,232(sp)
    80005efe:	7fce                	ld	t6,240(sp)
    80005f00:	6111                	addi	sp,sp,256
    80005f02:	10200073          	sret
    80005f06:	00000013          	nop
    80005f0a:	00000013          	nop
    80005f0e:	0001                	nop

0000000080005f10 <timervec>:
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	e10c                	sd	a1,0(a0)
    80005f16:	e510                	sd	a2,8(a0)
    80005f18:	e914                	sd	a3,16(a0)
    80005f1a:	6d0c                	ld	a1,24(a0)
    80005f1c:	7110                	ld	a2,32(a0)
    80005f1e:	6194                	ld	a3,0(a1)
    80005f20:	96b2                	add	a3,a3,a2
    80005f22:	e194                	sd	a3,0(a1)
    80005f24:	4589                	li	a1,2
    80005f26:	14459073          	csrw	sip,a1
    80005f2a:	6914                	ld	a3,16(a0)
    80005f2c:	6510                	ld	a2,8(a0)
    80005f2e:	610c                	ld	a1,0(a0)
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	30200073          	mret
	...

0000000080005f3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f3a:	1141                	addi	sp,sp,-16
    80005f3c:	e422                	sd	s0,8(sp)
    80005f3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f40:	0c0007b7          	lui	a5,0xc000
    80005f44:	4705                	li	a4,1
    80005f46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f48:	c3d8                	sw	a4,4(a5)
}
    80005f4a:	6422                	ld	s0,8(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret

0000000080005f50 <plicinithart>:

void
plicinithart(void)
{
    80005f50:	1141                	addi	sp,sp,-16
    80005f52:	e406                	sd	ra,8(sp)
    80005f54:	e022                	sd	s0,0(sp)
    80005f56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	a3c080e7          	jalr	-1476(ra) # 80001994 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f60:	0085171b          	slliw	a4,a0,0x8
    80005f64:	0c0027b7          	lui	a5,0xc002
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	40200713          	li	a4,1026
    80005f6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f72:	00d5151b          	slliw	a0,a0,0xd
    80005f76:	0c2017b7          	lui	a5,0xc201
    80005f7a:	953e                	add	a0,a0,a5
    80005f7c:	00052023          	sw	zero,0(a0)
}
    80005f80:	60a2                	ld	ra,8(sp)
    80005f82:	6402                	ld	s0,0(sp)
    80005f84:	0141                	addi	sp,sp,16
    80005f86:	8082                	ret

0000000080005f88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f88:	1141                	addi	sp,sp,-16
    80005f8a:	e406                	sd	ra,8(sp)
    80005f8c:	e022                	sd	s0,0(sp)
    80005f8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f90:	ffffc097          	auipc	ra,0xffffc
    80005f94:	a04080e7          	jalr	-1532(ra) # 80001994 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f98:	00d5179b          	slliw	a5,a0,0xd
    80005f9c:	0c201537          	lui	a0,0xc201
    80005fa0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fa2:	4148                	lw	a0,4(a0)
    80005fa4:	60a2                	ld	ra,8(sp)
    80005fa6:	6402                	ld	s0,0(sp)
    80005fa8:	0141                	addi	sp,sp,16
    80005faa:	8082                	ret

0000000080005fac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fac:	1101                	addi	sp,sp,-32
    80005fae:	ec06                	sd	ra,24(sp)
    80005fb0:	e822                	sd	s0,16(sp)
    80005fb2:	e426                	sd	s1,8(sp)
    80005fb4:	1000                	addi	s0,sp,32
    80005fb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	9dc080e7          	jalr	-1572(ra) # 80001994 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fc0:	00d5151b          	slliw	a0,a0,0xd
    80005fc4:	0c2017b7          	lui	a5,0xc201
    80005fc8:	97aa                	add	a5,a5,a0
    80005fca:	c3c4                	sw	s1,4(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret

0000000080005fd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fd6:	1141                	addi	sp,sp,-16
    80005fd8:	e406                	sd	ra,8(sp)
    80005fda:	e022                	sd	s0,0(sp)
    80005fdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fde:	479d                	li	a5,7
    80005fe0:	06a7c963          	blt	a5,a0,80006052 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005fe4:	0001d797          	auipc	a5,0x1d
    80005fe8:	01c78793          	addi	a5,a5,28 # 80023000 <disk>
    80005fec:	00a78733          	add	a4,a5,a0
    80005ff0:	6789                	lui	a5,0x2
    80005ff2:	97ba                	add	a5,a5,a4
    80005ff4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ff8:	e7ad                	bnez	a5,80006062 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ffa:	00451793          	slli	a5,a0,0x4
    80005ffe:	0001f717          	auipc	a4,0x1f
    80006002:	00270713          	addi	a4,a4,2 # 80025000 <disk+0x2000>
    80006006:	6314                	ld	a3,0(a4)
    80006008:	96be                	add	a3,a3,a5
    8000600a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000600e:	6314                	ld	a3,0(a4)
    80006010:	96be                	add	a3,a3,a5
    80006012:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006016:	6314                	ld	a3,0(a4)
    80006018:	96be                	add	a3,a3,a5
    8000601a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000601e:	6318                	ld	a4,0(a4)
    80006020:	97ba                	add	a5,a5,a4
    80006022:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006026:	0001d797          	auipc	a5,0x1d
    8000602a:	fda78793          	addi	a5,a5,-38 # 80023000 <disk>
    8000602e:	97aa                	add	a5,a5,a0
    80006030:	6509                	lui	a0,0x2
    80006032:	953e                	add	a0,a0,a5
    80006034:	4785                	li	a5,1
    80006036:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000603a:	0001f517          	auipc	a0,0x1f
    8000603e:	fde50513          	addi	a0,a0,-34 # 80025018 <disk+0x2018>
    80006042:	ffffc097          	auipc	ra,0xffffc
    80006046:	55a080e7          	jalr	1370(ra) # 8000259c <wakeup>
}
    8000604a:	60a2                	ld	ra,8(sp)
    8000604c:	6402                	ld	s0,0(sp)
    8000604e:	0141                	addi	sp,sp,16
    80006050:	8082                	ret
    panic("free_desc 1");
    80006052:	00002517          	auipc	a0,0x2
    80006056:	7d650513          	addi	a0,a0,2006 # 80008828 <syscalls+0x338>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e4080e7          	jalr	1252(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	7d650513          	addi	a0,a0,2006 # 80008838 <syscalls+0x348>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>

0000000080006072 <virtio_disk_init>:
{
    80006072:	1101                	addi	sp,sp,-32
    80006074:	ec06                	sd	ra,24(sp)
    80006076:	e822                	sd	s0,16(sp)
    80006078:	e426                	sd	s1,8(sp)
    8000607a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000607c:	00002597          	auipc	a1,0x2
    80006080:	7cc58593          	addi	a1,a1,1996 # 80008848 <syscalls+0x358>
    80006084:	0001f517          	auipc	a0,0x1f
    80006088:	0a450513          	addi	a0,a0,164 # 80025128 <disk+0x2128>
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	ac8080e7          	jalr	-1336(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006094:	100017b7          	lui	a5,0x10001
    80006098:	4398                	lw	a4,0(a5)
    8000609a:	2701                	sext.w	a4,a4
    8000609c:	747277b7          	lui	a5,0x74727
    800060a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060a4:	0ef71163          	bne	a4,a5,80006186 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060a8:	100017b7          	lui	a5,0x10001
    800060ac:	43dc                	lw	a5,4(a5)
    800060ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060b0:	4705                	li	a4,1
    800060b2:	0ce79a63          	bne	a5,a4,80006186 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060b6:	100017b7          	lui	a5,0x10001
    800060ba:	479c                	lw	a5,8(a5)
    800060bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060be:	4709                	li	a4,2
    800060c0:	0ce79363          	bne	a5,a4,80006186 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060c4:	100017b7          	lui	a5,0x10001
    800060c8:	47d8                	lw	a4,12(a5)
    800060ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060cc:	554d47b7          	lui	a5,0x554d4
    800060d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060d4:	0af71963          	bne	a4,a5,80006186 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d8:	100017b7          	lui	a5,0x10001
    800060dc:	4705                	li	a4,1
    800060de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e0:	470d                	li	a4,3
    800060e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060e6:	c7ffe737          	lui	a4,0xc7ffe
    800060ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800060ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060f0:	2701                	sext.w	a4,a4
    800060f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f4:	472d                	li	a4,11
    800060f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f8:	473d                	li	a4,15
    800060fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060fc:	6705                	lui	a4,0x1
    800060fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006100:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006104:	5bdc                	lw	a5,52(a5)
    80006106:	2781                	sext.w	a5,a5
  if(max == 0)
    80006108:	c7d9                	beqz	a5,80006196 <virtio_disk_init+0x124>
  if(max < NUM)
    8000610a:	471d                	li	a4,7
    8000610c:	08f77d63          	bgeu	a4,a5,800061a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006110:	100014b7          	lui	s1,0x10001
    80006114:	47a1                	li	a5,8
    80006116:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006118:	6609                	lui	a2,0x2
    8000611a:	4581                	li	a1,0
    8000611c:	0001d517          	auipc	a0,0x1d
    80006120:	ee450513          	addi	a0,a0,-284 # 80023000 <disk>
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	bbc080e7          	jalr	-1092(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000612c:	0001d717          	auipc	a4,0x1d
    80006130:	ed470713          	addi	a4,a4,-300 # 80023000 <disk>
    80006134:	00c75793          	srli	a5,a4,0xc
    80006138:	2781                	sext.w	a5,a5
    8000613a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000613c:	0001f797          	auipc	a5,0x1f
    80006140:	ec478793          	addi	a5,a5,-316 # 80025000 <disk+0x2000>
    80006144:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006146:	0001d717          	auipc	a4,0x1d
    8000614a:	f3a70713          	addi	a4,a4,-198 # 80023080 <disk+0x80>
    8000614e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006150:	0001e717          	auipc	a4,0x1e
    80006154:	eb070713          	addi	a4,a4,-336 # 80024000 <disk+0x1000>
    80006158:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000615a:	4705                	li	a4,1
    8000615c:	00e78c23          	sb	a4,24(a5)
    80006160:	00e78ca3          	sb	a4,25(a5)
    80006164:	00e78d23          	sb	a4,26(a5)
    80006168:	00e78da3          	sb	a4,27(a5)
    8000616c:	00e78e23          	sb	a4,28(a5)
    80006170:	00e78ea3          	sb	a4,29(a5)
    80006174:	00e78f23          	sb	a4,30(a5)
    80006178:	00e78fa3          	sb	a4,31(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret
    panic("could not find virtio disk");
    80006186:	00002517          	auipc	a0,0x2
    8000618a:	6d250513          	addi	a0,a0,1746 # 80008858 <syscalls+0x368>
    8000618e:	ffffa097          	auipc	ra,0xffffa
    80006192:	3b0080e7          	jalr	944(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006196:	00002517          	auipc	a0,0x2
    8000619a:	6e250513          	addi	a0,a0,1762 # 80008878 <syscalls+0x388>
    8000619e:	ffffa097          	auipc	ra,0xffffa
    800061a2:	3a0080e7          	jalr	928(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800061a6:	00002517          	auipc	a0,0x2
    800061aa:	6f250513          	addi	a0,a0,1778 # 80008898 <syscalls+0x3a8>
    800061ae:	ffffa097          	auipc	ra,0xffffa
    800061b2:	390080e7          	jalr	912(ra) # 8000053e <panic>

00000000800061b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b6:	7159                	addi	sp,sp,-112
    800061b8:	f486                	sd	ra,104(sp)
    800061ba:	f0a2                	sd	s0,96(sp)
    800061bc:	eca6                	sd	s1,88(sp)
    800061be:	e8ca                	sd	s2,80(sp)
    800061c0:	e4ce                	sd	s3,72(sp)
    800061c2:	e0d2                	sd	s4,64(sp)
    800061c4:	fc56                	sd	s5,56(sp)
    800061c6:	f85a                	sd	s6,48(sp)
    800061c8:	f45e                	sd	s7,40(sp)
    800061ca:	f062                	sd	s8,32(sp)
    800061cc:	ec66                	sd	s9,24(sp)
    800061ce:	e86a                	sd	s10,16(sp)
    800061d0:	1880                	addi	s0,sp,112
    800061d2:	892a                	mv	s2,a0
    800061d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d6:	00c52c83          	lw	s9,12(a0)
    800061da:	001c9c9b          	slliw	s9,s9,0x1
    800061de:	1c82                	slli	s9,s9,0x20
    800061e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061e4:	0001f517          	auipc	a0,0x1f
    800061e8:	f4450513          	addi	a0,a0,-188 # 80025128 <disk+0x2128>
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	9f8080e7          	jalr	-1544(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800061f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061f8:	0001db97          	auipc	s7,0x1d
    800061fc:	e08b8b93          	addi	s7,s7,-504 # 80023000 <disk>
    80006200:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006202:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006204:	8a4e                	mv	s4,s3
    80006206:	a051                	j	8000628a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006208:	00fb86b3          	add	a3,s7,a5
    8000620c:	96da                	add	a3,a3,s6
    8000620e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006212:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006214:	0207c563          	bltz	a5,8000623e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006218:	2485                	addiw	s1,s1,1
    8000621a:	0711                	addi	a4,a4,4
    8000621c:	25548063          	beq	s1,s5,8000645c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006220:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006222:	0001f697          	auipc	a3,0x1f
    80006226:	df668693          	addi	a3,a3,-522 # 80025018 <disk+0x2018>
    8000622a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000622c:	0006c583          	lbu	a1,0(a3)
    80006230:	fde1                	bnez	a1,80006208 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006232:	2785                	addiw	a5,a5,1
    80006234:	0685                	addi	a3,a3,1
    80006236:	ff879be3          	bne	a5,s8,8000622c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000623a:	57fd                	li	a5,-1
    8000623c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000623e:	02905a63          	blez	s1,80006272 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006242:	f9042503          	lw	a0,-112(s0)
    80006246:	00000097          	auipc	ra,0x0
    8000624a:	d90080e7          	jalr	-624(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    8000624e:	4785                	li	a5,1
    80006250:	0297d163          	bge	a5,s1,80006272 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006254:	f9442503          	lw	a0,-108(s0)
    80006258:	00000097          	auipc	ra,0x0
    8000625c:	d7e080e7          	jalr	-642(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006260:	4789                	li	a5,2
    80006262:	0097d863          	bge	a5,s1,80006272 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006266:	f9842503          	lw	a0,-104(s0)
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	d6c080e7          	jalr	-660(ra) # 80005fd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006272:	0001f597          	auipc	a1,0x1f
    80006276:	eb658593          	addi	a1,a1,-330 # 80025128 <disk+0x2128>
    8000627a:	0001f517          	auipc	a0,0x1f
    8000627e:	d9e50513          	addi	a0,a0,-610 # 80025018 <disk+0x2018>
    80006282:	ffffc097          	auipc	ra,0xffffc
    80006286:	182080e7          	jalr	386(ra) # 80002404 <sleep>
  for(int i = 0; i < 3; i++){
    8000628a:	f9040713          	addi	a4,s0,-112
    8000628e:	84ce                	mv	s1,s3
    80006290:	bf41                	j	80006220 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006292:	20058713          	addi	a4,a1,512
    80006296:	00471693          	slli	a3,a4,0x4
    8000629a:	0001d717          	auipc	a4,0x1d
    8000629e:	d6670713          	addi	a4,a4,-666 # 80023000 <disk>
    800062a2:	9736                	add	a4,a4,a3
    800062a4:	4685                	li	a3,1
    800062a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062aa:	20058713          	addi	a4,a1,512
    800062ae:	00471693          	slli	a3,a4,0x4
    800062b2:	0001d717          	auipc	a4,0x1d
    800062b6:	d4e70713          	addi	a4,a4,-690 # 80023000 <disk>
    800062ba:	9736                	add	a4,a4,a3
    800062bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c4:	7679                	lui	a2,0xffffe
    800062c6:	963e                	add	a2,a2,a5
    800062c8:	0001f697          	auipc	a3,0x1f
    800062cc:	d3868693          	addi	a3,a3,-712 # 80025000 <disk+0x2000>
    800062d0:	6298                	ld	a4,0(a3)
    800062d2:	9732                	add	a4,a4,a2
    800062d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062d6:	6298                	ld	a4,0(a3)
    800062d8:	9732                	add	a4,a4,a2
    800062da:	4541                	li	a0,16
    800062dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062de:	6298                	ld	a4,0(a3)
    800062e0:	9732                	add	a4,a4,a2
    800062e2:	4505                	li	a0,1
    800062e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062e8:	f9442703          	lw	a4,-108(s0)
    800062ec:	6288                	ld	a0,0(a3)
    800062ee:	962a                	add	a2,a2,a0
    800062f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062f4:	0712                	slli	a4,a4,0x4
    800062f6:	6290                	ld	a2,0(a3)
    800062f8:	963a                	add	a2,a2,a4
    800062fa:	05890513          	addi	a0,s2,88
    800062fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006300:	6294                	ld	a3,0(a3)
    80006302:	96ba                	add	a3,a3,a4
    80006304:	40000613          	li	a2,1024
    80006308:	c690                	sw	a2,8(a3)
  if(write)
    8000630a:	140d0063          	beqz	s10,8000644a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000630e:	0001f697          	auipc	a3,0x1f
    80006312:	cf26b683          	ld	a3,-782(a3) # 80025000 <disk+0x2000>
    80006316:	96ba                	add	a3,a3,a4
    80006318:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000631c:	0001d817          	auipc	a6,0x1d
    80006320:	ce480813          	addi	a6,a6,-796 # 80023000 <disk>
    80006324:	0001f517          	auipc	a0,0x1f
    80006328:	cdc50513          	addi	a0,a0,-804 # 80025000 <disk+0x2000>
    8000632c:	6114                	ld	a3,0(a0)
    8000632e:	96ba                	add	a3,a3,a4
    80006330:	00c6d603          	lhu	a2,12(a3)
    80006334:	00166613          	ori	a2,a2,1
    80006338:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000633c:	f9842683          	lw	a3,-104(s0)
    80006340:	6110                	ld	a2,0(a0)
    80006342:	9732                	add	a4,a4,a2
    80006344:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006348:	20058613          	addi	a2,a1,512
    8000634c:	0612                	slli	a2,a2,0x4
    8000634e:	9642                	add	a2,a2,a6
    80006350:	577d                	li	a4,-1
    80006352:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006356:	00469713          	slli	a4,a3,0x4
    8000635a:	6114                	ld	a3,0(a0)
    8000635c:	96ba                	add	a3,a3,a4
    8000635e:	03078793          	addi	a5,a5,48
    80006362:	97c2                	add	a5,a5,a6
    80006364:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006366:	611c                	ld	a5,0(a0)
    80006368:	97ba                	add	a5,a5,a4
    8000636a:	4685                	li	a3,1
    8000636c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000636e:	611c                	ld	a5,0(a0)
    80006370:	97ba                	add	a5,a5,a4
    80006372:	4809                	li	a6,2
    80006374:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006378:	611c                	ld	a5,0(a0)
    8000637a:	973e                	add	a4,a4,a5
    8000637c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006380:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006384:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006388:	6518                	ld	a4,8(a0)
    8000638a:	00275783          	lhu	a5,2(a4)
    8000638e:	8b9d                	andi	a5,a5,7
    80006390:	0786                	slli	a5,a5,0x1
    80006392:	97ba                	add	a5,a5,a4
    80006394:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006398:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000639c:	6518                	ld	a4,8(a0)
    8000639e:	00275783          	lhu	a5,2(a4)
    800063a2:	2785                	addiw	a5,a5,1
    800063a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ac:	100017b7          	lui	a5,0x10001
    800063b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063b4:	00492703          	lw	a4,4(s2)
    800063b8:	4785                	li	a5,1
    800063ba:	02f71163          	bne	a4,a5,800063dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800063be:	0001f997          	auipc	s3,0x1f
    800063c2:	d6a98993          	addi	s3,s3,-662 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800063c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063c8:	85ce                	mv	a1,s3
    800063ca:	854a                	mv	a0,s2
    800063cc:	ffffc097          	auipc	ra,0xffffc
    800063d0:	038080e7          	jalr	56(ra) # 80002404 <sleep>
  while(b->disk == 1) {
    800063d4:	00492783          	lw	a5,4(s2)
    800063d8:	fe9788e3          	beq	a5,s1,800063c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800063dc:	f9042903          	lw	s2,-112(s0)
    800063e0:	20090793          	addi	a5,s2,512
    800063e4:	00479713          	slli	a4,a5,0x4
    800063e8:	0001d797          	auipc	a5,0x1d
    800063ec:	c1878793          	addi	a5,a5,-1000 # 80023000 <disk>
    800063f0:	97ba                	add	a5,a5,a4
    800063f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063f6:	0001f997          	auipc	s3,0x1f
    800063fa:	c0a98993          	addi	s3,s3,-1014 # 80025000 <disk+0x2000>
    800063fe:	00491713          	slli	a4,s2,0x4
    80006402:	0009b783          	ld	a5,0(s3)
    80006406:	97ba                	add	a5,a5,a4
    80006408:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000640c:	854a                	mv	a0,s2
    8000640e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006412:	00000097          	auipc	ra,0x0
    80006416:	bc4080e7          	jalr	-1084(ra) # 80005fd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000641a:	8885                	andi	s1,s1,1
    8000641c:	f0ed                	bnez	s1,800063fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000641e:	0001f517          	auipc	a0,0x1f
    80006422:	d0a50513          	addi	a0,a0,-758 # 80025128 <disk+0x2128>
    80006426:	ffffb097          	auipc	ra,0xffffb
    8000642a:	872080e7          	jalr	-1934(ra) # 80000c98 <release>
}
    8000642e:	70a6                	ld	ra,104(sp)
    80006430:	7406                	ld	s0,96(sp)
    80006432:	64e6                	ld	s1,88(sp)
    80006434:	6946                	ld	s2,80(sp)
    80006436:	69a6                	ld	s3,72(sp)
    80006438:	6a06                	ld	s4,64(sp)
    8000643a:	7ae2                	ld	s5,56(sp)
    8000643c:	7b42                	ld	s6,48(sp)
    8000643e:	7ba2                	ld	s7,40(sp)
    80006440:	7c02                	ld	s8,32(sp)
    80006442:	6ce2                	ld	s9,24(sp)
    80006444:	6d42                	ld	s10,16(sp)
    80006446:	6165                	addi	sp,sp,112
    80006448:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000644a:	0001f697          	auipc	a3,0x1f
    8000644e:	bb66b683          	ld	a3,-1098(a3) # 80025000 <disk+0x2000>
    80006452:	96ba                	add	a3,a3,a4
    80006454:	4609                	li	a2,2
    80006456:	00c69623          	sh	a2,12(a3)
    8000645a:	b5c9                	j	8000631c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000645c:	f9042583          	lw	a1,-112(s0)
    80006460:	20058793          	addi	a5,a1,512
    80006464:	0792                	slli	a5,a5,0x4
    80006466:	0001d517          	auipc	a0,0x1d
    8000646a:	c4250513          	addi	a0,a0,-958 # 800230a8 <disk+0xa8>
    8000646e:	953e                	add	a0,a0,a5
  if(write)
    80006470:	e20d11e3          	bnez	s10,80006292 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006474:	20058713          	addi	a4,a1,512
    80006478:	00471693          	slli	a3,a4,0x4
    8000647c:	0001d717          	auipc	a4,0x1d
    80006480:	b8470713          	addi	a4,a4,-1148 # 80023000 <disk>
    80006484:	9736                	add	a4,a4,a3
    80006486:	0a072423          	sw	zero,168(a4)
    8000648a:	b505                	j	800062aa <virtio_disk_rw+0xf4>

000000008000648c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000648c:	1101                	addi	sp,sp,-32
    8000648e:	ec06                	sd	ra,24(sp)
    80006490:	e822                	sd	s0,16(sp)
    80006492:	e426                	sd	s1,8(sp)
    80006494:	e04a                	sd	s2,0(sp)
    80006496:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006498:	0001f517          	auipc	a0,0x1f
    8000649c:	c9050513          	addi	a0,a0,-880 # 80025128 <disk+0x2128>
    800064a0:	ffffa097          	auipc	ra,0xffffa
    800064a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064a8:	10001737          	lui	a4,0x10001
    800064ac:	533c                	lw	a5,96(a4)
    800064ae:	8b8d                	andi	a5,a5,3
    800064b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064b6:	0001f797          	auipc	a5,0x1f
    800064ba:	b4a78793          	addi	a5,a5,-1206 # 80025000 <disk+0x2000>
    800064be:	6b94                	ld	a3,16(a5)
    800064c0:	0207d703          	lhu	a4,32(a5)
    800064c4:	0026d783          	lhu	a5,2(a3)
    800064c8:	06f70163          	beq	a4,a5,8000652a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064cc:	0001d917          	auipc	s2,0x1d
    800064d0:	b3490913          	addi	s2,s2,-1228 # 80023000 <disk>
    800064d4:	0001f497          	auipc	s1,0x1f
    800064d8:	b2c48493          	addi	s1,s1,-1236 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064e0:	6898                	ld	a4,16(s1)
    800064e2:	0204d783          	lhu	a5,32(s1)
    800064e6:	8b9d                	andi	a5,a5,7
    800064e8:	078e                	slli	a5,a5,0x3
    800064ea:	97ba                	add	a5,a5,a4
    800064ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064ee:	20078713          	addi	a4,a5,512
    800064f2:	0712                	slli	a4,a4,0x4
    800064f4:	974a                	add	a4,a4,s2
    800064f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064fa:	e731                	bnez	a4,80006546 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064fc:	20078793          	addi	a5,a5,512
    80006500:	0792                	slli	a5,a5,0x4
    80006502:	97ca                	add	a5,a5,s2
    80006504:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006506:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000650a:	ffffc097          	auipc	ra,0xffffc
    8000650e:	092080e7          	jalr	146(ra) # 8000259c <wakeup>

    disk.used_idx += 1;
    80006512:	0204d783          	lhu	a5,32(s1)
    80006516:	2785                	addiw	a5,a5,1
    80006518:	17c2                	slli	a5,a5,0x30
    8000651a:	93c1                	srli	a5,a5,0x30
    8000651c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006520:	6898                	ld	a4,16(s1)
    80006522:	00275703          	lhu	a4,2(a4)
    80006526:	faf71be3          	bne	a4,a5,800064dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000652a:	0001f517          	auipc	a0,0x1f
    8000652e:	bfe50513          	addi	a0,a0,-1026 # 80025128 <disk+0x2128>
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	766080e7          	jalr	1894(ra) # 80000c98 <release>
}
    8000653a:	60e2                	ld	ra,24(sp)
    8000653c:	6442                	ld	s0,16(sp)
    8000653e:	64a2                	ld	s1,8(sp)
    80006540:	6902                	ld	s2,0(sp)
    80006542:	6105                	addi	sp,sp,32
    80006544:	8082                	ret
      panic("virtio_disk_intr status");
    80006546:	00002517          	auipc	a0,0x2
    8000654a:	37250513          	addi	a0,a0,882 # 800088b8 <syscalls+0x3c8>
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	ff0080e7          	jalr	-16(ra) # 8000053e <panic>
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
