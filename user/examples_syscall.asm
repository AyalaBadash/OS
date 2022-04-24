
user/_examples_syscall:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <example_pause_system>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void example_pause_system(int interval, int pause_seconds, int loop_size) {
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	e852                	sd	s4,16(sp)
   e:	e456                	sd	s5,8(sp)
  10:	e05a                	sd	s6,0(sp)
  12:	0080                	addi	s0,sp,64
  14:	8a2a                	mv	s4,a0
  16:	8aae                	mv	s5,a1
  18:	8932                	mv	s2,a2
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
  1a:	00000097          	auipc	ra,0x0
  1e:	3a8080e7          	jalr	936(ra) # 3c2 <fork>
  22:	00000097          	auipc	ra,0x0
  26:	3a0080e7          	jalr	928(ra) # 3c2 <fork>
    }
    for (int i = 0; i < (int)(loop_size); i++) {
  2a:	05205463          	blez	s2,72 <example_pause_system+0x72>
        if (i % interval == 0) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == (int)(loop_size / 2)){
  2e:	01f9599b          	srliw	s3,s2,0x1f
  32:	012989bb          	addw	s3,s3,s2
  36:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < (int)(loop_size); i++) {
  3a:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
  3c:	00001b17          	auipc	s6,0x1
  40:	8c4b0b13          	addi	s6,s6,-1852 # 900 <malloc+0xe8>
  44:	a829                	j	5e <example_pause_system+0x5e>
  46:	864a                	mv	a2,s2
  48:	85a6                	mv	a1,s1
  4a:	855a                	mv	a0,s6
  4c:	00000097          	auipc	ra,0x0
  50:	70e080e7          	jalr	1806(ra) # 75a <printf>
        if (i == (int)(loop_size / 2)){
  54:	00998963          	beq	s3,s1,66 <example_pause_system+0x66>
    for (int i = 0; i < (int)(loop_size); i++) {
  58:	2485                	addiw	s1,s1,1
  5a:	00990c63          	beq	s2,s1,72 <example_pause_system+0x72>
        if (i % interval == 0) {
  5e:	0344e7bb          	remw	a5,s1,s4
  62:	fbed                	bnez	a5,54 <example_pause_system+0x54>
  64:	b7cd                	j	46 <example_pause_system+0x46>
            pause_system((int)(pause_seconds));
  66:	8556                	mv	a0,s5
  68:	00000097          	auipc	ra,0x0
  6c:	402080e7          	jalr	1026(ra) # 46a <pause_system>
  70:	b7e5                	j	58 <example_pause_system+0x58>
        }
    }
    printf("\n");
  72:	00001517          	auipc	a0,0x1
  76:	8ae50513          	addi	a0,a0,-1874 # 920 <malloc+0x108>
  7a:	00000097          	auipc	ra,0x0
  7e:	6e0080e7          	jalr	1760(ra) # 75a <printf>
}
  82:	70e2                	ld	ra,56(sp)
  84:	7442                	ld	s0,48(sp)
  86:	74a2                	ld	s1,40(sp)
  88:	7902                	ld	s2,32(sp)
  8a:	69e2                	ld	s3,24(sp)
  8c:	6a42                	ld	s4,16(sp)
  8e:	6aa2                	ld	s5,8(sp)
  90:	6b02                	ld	s6,0(sp)
  92:	6121                	addi	sp,sp,64
  94:	8082                	ret

0000000000000096 <example_kill_system>:

void example_kill_system(int interval, int loop_size) {
  96:	7139                	addi	sp,sp,-64
  98:	fc06                	sd	ra,56(sp)
  9a:	f822                	sd	s0,48(sp)
  9c:	f426                	sd	s1,40(sp)
  9e:	f04a                	sd	s2,32(sp)
  a0:	ec4e                	sd	s3,24(sp)
  a2:	e852                	sd	s4,16(sp)
  a4:	e456                	sd	s5,8(sp)
  a6:	0080                	addi	s0,sp,64
  a8:	8a2a                	mv	s4,a0
  aa:	892e                	mv	s2,a1
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
  ac:	00000097          	auipc	ra,0x0
  b0:	316080e7          	jalr	790(ra) # 3c2 <fork>
  b4:	00000097          	auipc	ra,0x0
  b8:	30e080e7          	jalr	782(ra) # 3c2 <fork>
    }
    for (int i = 0; i < (int)(loop_size); i++) {
  bc:	05205363          	blez	s2,102 <example_kill_system+0x6c>
        if (i % interval == 0) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == (int)(loop_size / 2)){
  c0:	01f9599b          	srliw	s3,s2,0x1f
  c4:	012989bb          	addw	s3,s3,s2
  c8:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < (int)(loop_size); i++) {
  cc:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  ce:	00001a97          	auipc	s5,0x1
  d2:	85aa8a93          	addi	s5,s5,-1958 # 928 <malloc+0x110>
  d6:	a829                	j	f0 <example_kill_system+0x5a>
  d8:	864a                	mv	a2,s2
  da:	85a6                	mv	a1,s1
  dc:	8556                	mv	a0,s5
  de:	00000097          	auipc	ra,0x0
  e2:	67c080e7          	jalr	1660(ra) # 75a <printf>
        if (i == (int)(loop_size / 2)){
  e6:	00998963          	beq	s3,s1,f8 <example_kill_system+0x62>
    for (int i = 0; i < (int)(loop_size); i++) {
  ea:	2485                	addiw	s1,s1,1
  ec:	00990b63          	beq	s2,s1,102 <example_kill_system+0x6c>
        if (i % interval == 0) {
  f0:	0344e7bb          	remw	a5,s1,s4
  f4:	fbed                	bnez	a5,e6 <example_kill_system+0x50>
  f6:	b7cd                	j	d8 <example_kill_system+0x42>
            kill_system();
  f8:	00000097          	auipc	ra,0x0
  fc:	37a080e7          	jalr	890(ra) # 472 <kill_system>
 100:	b7ed                	j	ea <example_kill_system+0x54>
        }
    }
    printf("\n");
 102:	00001517          	auipc	a0,0x1
 106:	81e50513          	addi	a0,a0,-2018 # 920 <malloc+0x108>
 10a:	00000097          	auipc	ra,0x0
 10e:	650080e7          	jalr	1616(ra) # 75a <printf>
}
 112:	70e2                	ld	ra,56(sp)
 114:	7442                	ld	s0,48(sp)
 116:	74a2                	ld	s1,40(sp)
 118:	7902                	ld	s2,32(sp)
 11a:	69e2                	ld	s3,24(sp)
 11c:	6a42                	ld	s4,16(sp)
 11e:	6aa2                	ld	s5,8(sp)
 120:	6121                	addi	sp,sp,64
 122:	8082                	ret

0000000000000124 <main>:

int main(int argc, char *argv[])
{
 124:	1141                	addi	sp,sp,-16
 126:	e406                	sd	ra,8(sp)
 128:	e022                	sd	s0,0(sp)
 12a:	0800                	addi	s0,sp,16
    example_pause_system(10, 10, 100);
 12c:	06400613          	li	a2,100
 130:	45a9                	li	a1,10
 132:	4529                	li	a0,10
 134:	00000097          	auipc	ra,0x0
 138:	ecc080e7          	jalr	-308(ra) # 0 <example_pause_system>
    example_kill_system(10, 100);
 13c:	06400593          	li	a1,100
 140:	4529                	li	a0,10
 142:	00000097          	auipc	ra,0x0
 146:	f54080e7          	jalr	-172(ra) # 96 <example_kill_system>
    exit(0);
 14a:	4501                	li	a0,0
 14c:	00000097          	auipc	ra,0x0
 150:	27e080e7          	jalr	638(ra) # 3ca <exit>

0000000000000154 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 154:	1141                	addi	sp,sp,-16
 156:	e422                	sd	s0,8(sp)
 158:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 15a:	87aa                	mv	a5,a0
 15c:	0585                	addi	a1,a1,1
 15e:	0785                	addi	a5,a5,1
 160:	fff5c703          	lbu	a4,-1(a1)
 164:	fee78fa3          	sb	a4,-1(a5)
 168:	fb75                	bnez	a4,15c <strcpy+0x8>
    ;
  return os;
}
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret

0000000000000170 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 170:	1141                	addi	sp,sp,-16
 172:	e422                	sd	s0,8(sp)
 174:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 176:	00054783          	lbu	a5,0(a0)
 17a:	cb91                	beqz	a5,18e <strcmp+0x1e>
 17c:	0005c703          	lbu	a4,0(a1)
 180:	00f71763          	bne	a4,a5,18e <strcmp+0x1e>
    p++, q++;
 184:	0505                	addi	a0,a0,1
 186:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 188:	00054783          	lbu	a5,0(a0)
 18c:	fbe5                	bnez	a5,17c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 18e:	0005c503          	lbu	a0,0(a1)
}
 192:	40a7853b          	subw	a0,a5,a0
 196:	6422                	ld	s0,8(sp)
 198:	0141                	addi	sp,sp,16
 19a:	8082                	ret

000000000000019c <strlen>:

uint
strlen(const char *s)
{
 19c:	1141                	addi	sp,sp,-16
 19e:	e422                	sd	s0,8(sp)
 1a0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1a2:	00054783          	lbu	a5,0(a0)
 1a6:	cf91                	beqz	a5,1c2 <strlen+0x26>
 1a8:	0505                	addi	a0,a0,1
 1aa:	87aa                	mv	a5,a0
 1ac:	4685                	li	a3,1
 1ae:	9e89                	subw	a3,a3,a0
 1b0:	00f6853b          	addw	a0,a3,a5
 1b4:	0785                	addi	a5,a5,1
 1b6:	fff7c703          	lbu	a4,-1(a5)
 1ba:	fb7d                	bnez	a4,1b0 <strlen+0x14>
    ;
  return n;
}
 1bc:	6422                	ld	s0,8(sp)
 1be:	0141                	addi	sp,sp,16
 1c0:	8082                	ret
  for(n = 0; s[n]; n++)
 1c2:	4501                	li	a0,0
 1c4:	bfe5                	j	1bc <strlen+0x20>

00000000000001c6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1c6:	1141                	addi	sp,sp,-16
 1c8:	e422                	sd	s0,8(sp)
 1ca:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1cc:	ce09                	beqz	a2,1e6 <memset+0x20>
 1ce:	87aa                	mv	a5,a0
 1d0:	fff6071b          	addiw	a4,a2,-1
 1d4:	1702                	slli	a4,a4,0x20
 1d6:	9301                	srli	a4,a4,0x20
 1d8:	0705                	addi	a4,a4,1
 1da:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1dc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1e0:	0785                	addi	a5,a5,1
 1e2:	fee79de3          	bne	a5,a4,1dc <memset+0x16>
  }
  return dst;
}
 1e6:	6422                	ld	s0,8(sp)
 1e8:	0141                	addi	sp,sp,16
 1ea:	8082                	ret

00000000000001ec <strchr>:

char*
strchr(const char *s, char c)
{
 1ec:	1141                	addi	sp,sp,-16
 1ee:	e422                	sd	s0,8(sp)
 1f0:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1f2:	00054783          	lbu	a5,0(a0)
 1f6:	cb99                	beqz	a5,20c <strchr+0x20>
    if(*s == c)
 1f8:	00f58763          	beq	a1,a5,206 <strchr+0x1a>
  for(; *s; s++)
 1fc:	0505                	addi	a0,a0,1
 1fe:	00054783          	lbu	a5,0(a0)
 202:	fbfd                	bnez	a5,1f8 <strchr+0xc>
      return (char*)s;
  return 0;
 204:	4501                	li	a0,0
}
 206:	6422                	ld	s0,8(sp)
 208:	0141                	addi	sp,sp,16
 20a:	8082                	ret
  return 0;
 20c:	4501                	li	a0,0
 20e:	bfe5                	j	206 <strchr+0x1a>

0000000000000210 <gets>:

char*
gets(char *buf, int max)
{
 210:	711d                	addi	sp,sp,-96
 212:	ec86                	sd	ra,88(sp)
 214:	e8a2                	sd	s0,80(sp)
 216:	e4a6                	sd	s1,72(sp)
 218:	e0ca                	sd	s2,64(sp)
 21a:	fc4e                	sd	s3,56(sp)
 21c:	f852                	sd	s4,48(sp)
 21e:	f456                	sd	s5,40(sp)
 220:	f05a                	sd	s6,32(sp)
 222:	ec5e                	sd	s7,24(sp)
 224:	1080                	addi	s0,sp,96
 226:	8baa                	mv	s7,a0
 228:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 22a:	892a                	mv	s2,a0
 22c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 22e:	4aa9                	li	s5,10
 230:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 232:	89a6                	mv	s3,s1
 234:	2485                	addiw	s1,s1,1
 236:	0344d863          	bge	s1,s4,266 <gets+0x56>
    cc = read(0, &c, 1);
 23a:	4605                	li	a2,1
 23c:	faf40593          	addi	a1,s0,-81
 240:	4501                	li	a0,0
 242:	00000097          	auipc	ra,0x0
 246:	1a0080e7          	jalr	416(ra) # 3e2 <read>
    if(cc < 1)
 24a:	00a05e63          	blez	a0,266 <gets+0x56>
    buf[i++] = c;
 24e:	faf44783          	lbu	a5,-81(s0)
 252:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 256:	01578763          	beq	a5,s5,264 <gets+0x54>
 25a:	0905                	addi	s2,s2,1
 25c:	fd679be3          	bne	a5,s6,232 <gets+0x22>
  for(i=0; i+1 < max; ){
 260:	89a6                	mv	s3,s1
 262:	a011                	j	266 <gets+0x56>
 264:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 266:	99de                	add	s3,s3,s7
 268:	00098023          	sb	zero,0(s3)
  return buf;
}
 26c:	855e                	mv	a0,s7
 26e:	60e6                	ld	ra,88(sp)
 270:	6446                	ld	s0,80(sp)
 272:	64a6                	ld	s1,72(sp)
 274:	6906                	ld	s2,64(sp)
 276:	79e2                	ld	s3,56(sp)
 278:	7a42                	ld	s4,48(sp)
 27a:	7aa2                	ld	s5,40(sp)
 27c:	7b02                	ld	s6,32(sp)
 27e:	6be2                	ld	s7,24(sp)
 280:	6125                	addi	sp,sp,96
 282:	8082                	ret

0000000000000284 <stat>:

int
stat(const char *n, struct stat *st)
{
 284:	1101                	addi	sp,sp,-32
 286:	ec06                	sd	ra,24(sp)
 288:	e822                	sd	s0,16(sp)
 28a:	e426                	sd	s1,8(sp)
 28c:	e04a                	sd	s2,0(sp)
 28e:	1000                	addi	s0,sp,32
 290:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 292:	4581                	li	a1,0
 294:	00000097          	auipc	ra,0x0
 298:	176080e7          	jalr	374(ra) # 40a <open>
  if(fd < 0)
 29c:	02054563          	bltz	a0,2c6 <stat+0x42>
 2a0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2a2:	85ca                	mv	a1,s2
 2a4:	00000097          	auipc	ra,0x0
 2a8:	17e080e7          	jalr	382(ra) # 422 <fstat>
 2ac:	892a                	mv	s2,a0
  close(fd);
 2ae:	8526                	mv	a0,s1
 2b0:	00000097          	auipc	ra,0x0
 2b4:	142080e7          	jalr	322(ra) # 3f2 <close>
  return r;
}
 2b8:	854a                	mv	a0,s2
 2ba:	60e2                	ld	ra,24(sp)
 2bc:	6442                	ld	s0,16(sp)
 2be:	64a2                	ld	s1,8(sp)
 2c0:	6902                	ld	s2,0(sp)
 2c2:	6105                	addi	sp,sp,32
 2c4:	8082                	ret
    return -1;
 2c6:	597d                	li	s2,-1
 2c8:	bfc5                	j	2b8 <stat+0x34>

00000000000002ca <atoi>:

int
atoi(const char *s)
{
 2ca:	1141                	addi	sp,sp,-16
 2cc:	e422                	sd	s0,8(sp)
 2ce:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2d0:	00054603          	lbu	a2,0(a0)
 2d4:	fd06079b          	addiw	a5,a2,-48
 2d8:	0ff7f793          	andi	a5,a5,255
 2dc:	4725                	li	a4,9
 2de:	02f76963          	bltu	a4,a5,310 <atoi+0x46>
 2e2:	86aa                	mv	a3,a0
  n = 0;
 2e4:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2e6:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2e8:	0685                	addi	a3,a3,1
 2ea:	0025179b          	slliw	a5,a0,0x2
 2ee:	9fa9                	addw	a5,a5,a0
 2f0:	0017979b          	slliw	a5,a5,0x1
 2f4:	9fb1                	addw	a5,a5,a2
 2f6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2fa:	0006c603          	lbu	a2,0(a3)
 2fe:	fd06071b          	addiw	a4,a2,-48
 302:	0ff77713          	andi	a4,a4,255
 306:	fee5f1e3          	bgeu	a1,a4,2e8 <atoi+0x1e>
  return n;
}
 30a:	6422                	ld	s0,8(sp)
 30c:	0141                	addi	sp,sp,16
 30e:	8082                	ret
  n = 0;
 310:	4501                	li	a0,0
 312:	bfe5                	j	30a <atoi+0x40>

0000000000000314 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 314:	1141                	addi	sp,sp,-16
 316:	e422                	sd	s0,8(sp)
 318:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 31a:	02b57663          	bgeu	a0,a1,346 <memmove+0x32>
    while(n-- > 0)
 31e:	02c05163          	blez	a2,340 <memmove+0x2c>
 322:	fff6079b          	addiw	a5,a2,-1
 326:	1782                	slli	a5,a5,0x20
 328:	9381                	srli	a5,a5,0x20
 32a:	0785                	addi	a5,a5,1
 32c:	97aa                	add	a5,a5,a0
  dst = vdst;
 32e:	872a                	mv	a4,a0
      *dst++ = *src++;
 330:	0585                	addi	a1,a1,1
 332:	0705                	addi	a4,a4,1
 334:	fff5c683          	lbu	a3,-1(a1)
 338:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 33c:	fee79ae3          	bne	a5,a4,330 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 340:	6422                	ld	s0,8(sp)
 342:	0141                	addi	sp,sp,16
 344:	8082                	ret
    dst += n;
 346:	00c50733          	add	a4,a0,a2
    src += n;
 34a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 34c:	fec05ae3          	blez	a2,340 <memmove+0x2c>
 350:	fff6079b          	addiw	a5,a2,-1
 354:	1782                	slli	a5,a5,0x20
 356:	9381                	srli	a5,a5,0x20
 358:	fff7c793          	not	a5,a5
 35c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 35e:	15fd                	addi	a1,a1,-1
 360:	177d                	addi	a4,a4,-1
 362:	0005c683          	lbu	a3,0(a1)
 366:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 36a:	fee79ae3          	bne	a5,a4,35e <memmove+0x4a>
 36e:	bfc9                	j	340 <memmove+0x2c>

0000000000000370 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 370:	1141                	addi	sp,sp,-16
 372:	e422                	sd	s0,8(sp)
 374:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 376:	ca05                	beqz	a2,3a6 <memcmp+0x36>
 378:	fff6069b          	addiw	a3,a2,-1
 37c:	1682                	slli	a3,a3,0x20
 37e:	9281                	srli	a3,a3,0x20
 380:	0685                	addi	a3,a3,1
 382:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 384:	00054783          	lbu	a5,0(a0)
 388:	0005c703          	lbu	a4,0(a1)
 38c:	00e79863          	bne	a5,a4,39c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 390:	0505                	addi	a0,a0,1
    p2++;
 392:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 394:	fed518e3          	bne	a0,a3,384 <memcmp+0x14>
  }
  return 0;
 398:	4501                	li	a0,0
 39a:	a019                	j	3a0 <memcmp+0x30>
      return *p1 - *p2;
 39c:	40e7853b          	subw	a0,a5,a4
}
 3a0:	6422                	ld	s0,8(sp)
 3a2:	0141                	addi	sp,sp,16
 3a4:	8082                	ret
  return 0;
 3a6:	4501                	li	a0,0
 3a8:	bfe5                	j	3a0 <memcmp+0x30>

00000000000003aa <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3aa:	1141                	addi	sp,sp,-16
 3ac:	e406                	sd	ra,8(sp)
 3ae:	e022                	sd	s0,0(sp)
 3b0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3b2:	00000097          	auipc	ra,0x0
 3b6:	f62080e7          	jalr	-158(ra) # 314 <memmove>
}
 3ba:	60a2                	ld	ra,8(sp)
 3bc:	6402                	ld	s0,0(sp)
 3be:	0141                	addi	sp,sp,16
 3c0:	8082                	ret

00000000000003c2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3c2:	4885                	li	a7,1
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <exit>:
.global exit
exit:
 li a7, SYS_exit
 3ca:	4889                	li	a7,2
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3d2:	488d                	li	a7,3
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3da:	4891                	li	a7,4
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <read>:
.global read
read:
 li a7, SYS_read
 3e2:	4895                	li	a7,5
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <write>:
.global write
write:
 li a7, SYS_write
 3ea:	48c1                	li	a7,16
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <close>:
.global close
close:
 li a7, SYS_close
 3f2:	48d5                	li	a7,21
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <kill>:
.global kill
kill:
 li a7, SYS_kill
 3fa:	4899                	li	a7,6
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <exec>:
.global exec
exec:
 li a7, SYS_exec
 402:	489d                	li	a7,7
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <open>:
.global open
open:
 li a7, SYS_open
 40a:	48bd                	li	a7,15
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 412:	48c5                	li	a7,17
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 41a:	48c9                	li	a7,18
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 422:	48a1                	li	a7,8
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <link>:
.global link
link:
 li a7, SYS_link
 42a:	48cd                	li	a7,19
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 432:	48d1                	li	a7,20
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 43a:	48a5                	li	a7,9
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <dup>:
.global dup
dup:
 li a7, SYS_dup
 442:	48a9                	li	a7,10
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 44a:	48ad                	li	a7,11
 ecall
 44c:	00000073          	ecall
 ret
 450:	8082                	ret

0000000000000452 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 452:	48b1                	li	a7,12
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 45a:	48b5                	li	a7,13
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 462:	48b9                	li	a7,14
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 46a:	48d9                	li	a7,22
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 472:	48dd                	li	a7,23
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 47a:	48e1                	li	a7,24
 ecall
 47c:	00000073          	ecall
 ret
 480:	8082                	ret

0000000000000482 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 482:	1101                	addi	sp,sp,-32
 484:	ec06                	sd	ra,24(sp)
 486:	e822                	sd	s0,16(sp)
 488:	1000                	addi	s0,sp,32
 48a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 48e:	4605                	li	a2,1
 490:	fef40593          	addi	a1,s0,-17
 494:	00000097          	auipc	ra,0x0
 498:	f56080e7          	jalr	-170(ra) # 3ea <write>
}
 49c:	60e2                	ld	ra,24(sp)
 49e:	6442                	ld	s0,16(sp)
 4a0:	6105                	addi	sp,sp,32
 4a2:	8082                	ret

00000000000004a4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4a4:	7139                	addi	sp,sp,-64
 4a6:	fc06                	sd	ra,56(sp)
 4a8:	f822                	sd	s0,48(sp)
 4aa:	f426                	sd	s1,40(sp)
 4ac:	f04a                	sd	s2,32(sp)
 4ae:	ec4e                	sd	s3,24(sp)
 4b0:	0080                	addi	s0,sp,64
 4b2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4b4:	c299                	beqz	a3,4ba <printint+0x16>
 4b6:	0805c863          	bltz	a1,546 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4ba:	2581                	sext.w	a1,a1
  neg = 0;
 4bc:	4881                	li	a7,0
 4be:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4c2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4c4:	2601                	sext.w	a2,a2
 4c6:	00000517          	auipc	a0,0x0
 4ca:	48a50513          	addi	a0,a0,1162 # 950 <digits>
 4ce:	883a                	mv	a6,a4
 4d0:	2705                	addiw	a4,a4,1
 4d2:	02c5f7bb          	remuw	a5,a1,a2
 4d6:	1782                	slli	a5,a5,0x20
 4d8:	9381                	srli	a5,a5,0x20
 4da:	97aa                	add	a5,a5,a0
 4dc:	0007c783          	lbu	a5,0(a5)
 4e0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4e4:	0005879b          	sext.w	a5,a1
 4e8:	02c5d5bb          	divuw	a1,a1,a2
 4ec:	0685                	addi	a3,a3,1
 4ee:	fec7f0e3          	bgeu	a5,a2,4ce <printint+0x2a>
  if(neg)
 4f2:	00088b63          	beqz	a7,508 <printint+0x64>
    buf[i++] = '-';
 4f6:	fd040793          	addi	a5,s0,-48
 4fa:	973e                	add	a4,a4,a5
 4fc:	02d00793          	li	a5,45
 500:	fef70823          	sb	a5,-16(a4)
 504:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 508:	02e05863          	blez	a4,538 <printint+0x94>
 50c:	fc040793          	addi	a5,s0,-64
 510:	00e78933          	add	s2,a5,a4
 514:	fff78993          	addi	s3,a5,-1
 518:	99ba                	add	s3,s3,a4
 51a:	377d                	addiw	a4,a4,-1
 51c:	1702                	slli	a4,a4,0x20
 51e:	9301                	srli	a4,a4,0x20
 520:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 524:	fff94583          	lbu	a1,-1(s2)
 528:	8526                	mv	a0,s1
 52a:	00000097          	auipc	ra,0x0
 52e:	f58080e7          	jalr	-168(ra) # 482 <putc>
  while(--i >= 0)
 532:	197d                	addi	s2,s2,-1
 534:	ff3918e3          	bne	s2,s3,524 <printint+0x80>
}
 538:	70e2                	ld	ra,56(sp)
 53a:	7442                	ld	s0,48(sp)
 53c:	74a2                	ld	s1,40(sp)
 53e:	7902                	ld	s2,32(sp)
 540:	69e2                	ld	s3,24(sp)
 542:	6121                	addi	sp,sp,64
 544:	8082                	ret
    x = -xx;
 546:	40b005bb          	negw	a1,a1
    neg = 1;
 54a:	4885                	li	a7,1
    x = -xx;
 54c:	bf8d                	j	4be <printint+0x1a>

000000000000054e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 54e:	7119                	addi	sp,sp,-128
 550:	fc86                	sd	ra,120(sp)
 552:	f8a2                	sd	s0,112(sp)
 554:	f4a6                	sd	s1,104(sp)
 556:	f0ca                	sd	s2,96(sp)
 558:	ecce                	sd	s3,88(sp)
 55a:	e8d2                	sd	s4,80(sp)
 55c:	e4d6                	sd	s5,72(sp)
 55e:	e0da                	sd	s6,64(sp)
 560:	fc5e                	sd	s7,56(sp)
 562:	f862                	sd	s8,48(sp)
 564:	f466                	sd	s9,40(sp)
 566:	f06a                	sd	s10,32(sp)
 568:	ec6e                	sd	s11,24(sp)
 56a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 56c:	0005c903          	lbu	s2,0(a1)
 570:	18090f63          	beqz	s2,70e <vprintf+0x1c0>
 574:	8aaa                	mv	s5,a0
 576:	8b32                	mv	s6,a2
 578:	00158493          	addi	s1,a1,1
  state = 0;
 57c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 57e:	02500a13          	li	s4,37
      if(c == 'd'){
 582:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 586:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 58a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 58e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 592:	00000b97          	auipc	s7,0x0
 596:	3beb8b93          	addi	s7,s7,958 # 950 <digits>
 59a:	a839                	j	5b8 <vprintf+0x6a>
        putc(fd, c);
 59c:	85ca                	mv	a1,s2
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	ee2080e7          	jalr	-286(ra) # 482 <putc>
 5a8:	a019                	j	5ae <vprintf+0x60>
    } else if(state == '%'){
 5aa:	01498f63          	beq	s3,s4,5c8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5ae:	0485                	addi	s1,s1,1
 5b0:	fff4c903          	lbu	s2,-1(s1)
 5b4:	14090d63          	beqz	s2,70e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5b8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5bc:	fe0997e3          	bnez	s3,5aa <vprintf+0x5c>
      if(c == '%'){
 5c0:	fd479ee3          	bne	a5,s4,59c <vprintf+0x4e>
        state = '%';
 5c4:	89be                	mv	s3,a5
 5c6:	b7e5                	j	5ae <vprintf+0x60>
      if(c == 'd'){
 5c8:	05878063          	beq	a5,s8,608 <vprintf+0xba>
      } else if(c == 'l') {
 5cc:	05978c63          	beq	a5,s9,624 <vprintf+0xd6>
      } else if(c == 'x') {
 5d0:	07a78863          	beq	a5,s10,640 <vprintf+0xf2>
      } else if(c == 'p') {
 5d4:	09b78463          	beq	a5,s11,65c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5d8:	07300713          	li	a4,115
 5dc:	0ce78663          	beq	a5,a4,6a8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5e0:	06300713          	li	a4,99
 5e4:	0ee78e63          	beq	a5,a4,6e0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5e8:	11478863          	beq	a5,s4,6f8 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5ec:	85d2                	mv	a1,s4
 5ee:	8556                	mv	a0,s5
 5f0:	00000097          	auipc	ra,0x0
 5f4:	e92080e7          	jalr	-366(ra) # 482 <putc>
        putc(fd, c);
 5f8:	85ca                	mv	a1,s2
 5fa:	8556                	mv	a0,s5
 5fc:	00000097          	auipc	ra,0x0
 600:	e86080e7          	jalr	-378(ra) # 482 <putc>
      }
      state = 0;
 604:	4981                	li	s3,0
 606:	b765                	j	5ae <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 608:	008b0913          	addi	s2,s6,8
 60c:	4685                	li	a3,1
 60e:	4629                	li	a2,10
 610:	000b2583          	lw	a1,0(s6)
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	e8e080e7          	jalr	-370(ra) # 4a4 <printint>
 61e:	8b4a                	mv	s6,s2
      state = 0;
 620:	4981                	li	s3,0
 622:	b771                	j	5ae <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 624:	008b0913          	addi	s2,s6,8
 628:	4681                	li	a3,0
 62a:	4629                	li	a2,10
 62c:	000b2583          	lw	a1,0(s6)
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e72080e7          	jalr	-398(ra) # 4a4 <printint>
 63a:	8b4a                	mv	s6,s2
      state = 0;
 63c:	4981                	li	s3,0
 63e:	bf85                	j	5ae <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 640:	008b0913          	addi	s2,s6,8
 644:	4681                	li	a3,0
 646:	4641                	li	a2,16
 648:	000b2583          	lw	a1,0(s6)
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	e56080e7          	jalr	-426(ra) # 4a4 <printint>
 656:	8b4a                	mv	s6,s2
      state = 0;
 658:	4981                	li	s3,0
 65a:	bf91                	j	5ae <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 65c:	008b0793          	addi	a5,s6,8
 660:	f8f43423          	sd	a5,-120(s0)
 664:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 668:	03000593          	li	a1,48
 66c:	8556                	mv	a0,s5
 66e:	00000097          	auipc	ra,0x0
 672:	e14080e7          	jalr	-492(ra) # 482 <putc>
  putc(fd, 'x');
 676:	85ea                	mv	a1,s10
 678:	8556                	mv	a0,s5
 67a:	00000097          	auipc	ra,0x0
 67e:	e08080e7          	jalr	-504(ra) # 482 <putc>
 682:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 684:	03c9d793          	srli	a5,s3,0x3c
 688:	97de                	add	a5,a5,s7
 68a:	0007c583          	lbu	a1,0(a5)
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	df2080e7          	jalr	-526(ra) # 482 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 698:	0992                	slli	s3,s3,0x4
 69a:	397d                	addiw	s2,s2,-1
 69c:	fe0914e3          	bnez	s2,684 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6a0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	b721                	j	5ae <vprintf+0x60>
        s = va_arg(ap, char*);
 6a8:	008b0993          	addi	s3,s6,8
 6ac:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6b0:	02090163          	beqz	s2,6d2 <vprintf+0x184>
        while(*s != 0){
 6b4:	00094583          	lbu	a1,0(s2)
 6b8:	c9a1                	beqz	a1,708 <vprintf+0x1ba>
          putc(fd, *s);
 6ba:	8556                	mv	a0,s5
 6bc:	00000097          	auipc	ra,0x0
 6c0:	dc6080e7          	jalr	-570(ra) # 482 <putc>
          s++;
 6c4:	0905                	addi	s2,s2,1
        while(*s != 0){
 6c6:	00094583          	lbu	a1,0(s2)
 6ca:	f9e5                	bnez	a1,6ba <vprintf+0x16c>
        s = va_arg(ap, char*);
 6cc:	8b4e                	mv	s6,s3
      state = 0;
 6ce:	4981                	li	s3,0
 6d0:	bdf9                	j	5ae <vprintf+0x60>
          s = "(null)";
 6d2:	00000917          	auipc	s2,0x0
 6d6:	27690913          	addi	s2,s2,630 # 948 <malloc+0x130>
        while(*s != 0){
 6da:	02800593          	li	a1,40
 6de:	bff1                	j	6ba <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6e0:	008b0913          	addi	s2,s6,8
 6e4:	000b4583          	lbu	a1,0(s6)
 6e8:	8556                	mv	a0,s5
 6ea:	00000097          	auipc	ra,0x0
 6ee:	d98080e7          	jalr	-616(ra) # 482 <putc>
 6f2:	8b4a                	mv	s6,s2
      state = 0;
 6f4:	4981                	li	s3,0
 6f6:	bd65                	j	5ae <vprintf+0x60>
        putc(fd, c);
 6f8:	85d2                	mv	a1,s4
 6fa:	8556                	mv	a0,s5
 6fc:	00000097          	auipc	ra,0x0
 700:	d86080e7          	jalr	-634(ra) # 482 <putc>
      state = 0;
 704:	4981                	li	s3,0
 706:	b565                	j	5ae <vprintf+0x60>
        s = va_arg(ap, char*);
 708:	8b4e                	mv	s6,s3
      state = 0;
 70a:	4981                	li	s3,0
 70c:	b54d                	j	5ae <vprintf+0x60>
    }
  }
}
 70e:	70e6                	ld	ra,120(sp)
 710:	7446                	ld	s0,112(sp)
 712:	74a6                	ld	s1,104(sp)
 714:	7906                	ld	s2,96(sp)
 716:	69e6                	ld	s3,88(sp)
 718:	6a46                	ld	s4,80(sp)
 71a:	6aa6                	ld	s5,72(sp)
 71c:	6b06                	ld	s6,64(sp)
 71e:	7be2                	ld	s7,56(sp)
 720:	7c42                	ld	s8,48(sp)
 722:	7ca2                	ld	s9,40(sp)
 724:	7d02                	ld	s10,32(sp)
 726:	6de2                	ld	s11,24(sp)
 728:	6109                	addi	sp,sp,128
 72a:	8082                	ret

000000000000072c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 72c:	715d                	addi	sp,sp,-80
 72e:	ec06                	sd	ra,24(sp)
 730:	e822                	sd	s0,16(sp)
 732:	1000                	addi	s0,sp,32
 734:	e010                	sd	a2,0(s0)
 736:	e414                	sd	a3,8(s0)
 738:	e818                	sd	a4,16(s0)
 73a:	ec1c                	sd	a5,24(s0)
 73c:	03043023          	sd	a6,32(s0)
 740:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 744:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 748:	8622                	mv	a2,s0
 74a:	00000097          	auipc	ra,0x0
 74e:	e04080e7          	jalr	-508(ra) # 54e <vprintf>
}
 752:	60e2                	ld	ra,24(sp)
 754:	6442                	ld	s0,16(sp)
 756:	6161                	addi	sp,sp,80
 758:	8082                	ret

000000000000075a <printf>:

void
printf(const char *fmt, ...)
{
 75a:	711d                	addi	sp,sp,-96
 75c:	ec06                	sd	ra,24(sp)
 75e:	e822                	sd	s0,16(sp)
 760:	1000                	addi	s0,sp,32
 762:	e40c                	sd	a1,8(s0)
 764:	e810                	sd	a2,16(s0)
 766:	ec14                	sd	a3,24(s0)
 768:	f018                	sd	a4,32(s0)
 76a:	f41c                	sd	a5,40(s0)
 76c:	03043823          	sd	a6,48(s0)
 770:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 774:	00840613          	addi	a2,s0,8
 778:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 77c:	85aa                	mv	a1,a0
 77e:	4505                	li	a0,1
 780:	00000097          	auipc	ra,0x0
 784:	dce080e7          	jalr	-562(ra) # 54e <vprintf>
}
 788:	60e2                	ld	ra,24(sp)
 78a:	6442                	ld	s0,16(sp)
 78c:	6125                	addi	sp,sp,96
 78e:	8082                	ret

0000000000000790 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 790:	1141                	addi	sp,sp,-16
 792:	e422                	sd	s0,8(sp)
 794:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 796:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 79a:	00000797          	auipc	a5,0x0
 79e:	1ce7b783          	ld	a5,462(a5) # 968 <freep>
 7a2:	a805                	j	7d2 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7a4:	4618                	lw	a4,8(a2)
 7a6:	9db9                	addw	a1,a1,a4
 7a8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7ac:	6398                	ld	a4,0(a5)
 7ae:	6318                	ld	a4,0(a4)
 7b0:	fee53823          	sd	a4,-16(a0)
 7b4:	a091                	j	7f8 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7b6:	ff852703          	lw	a4,-8(a0)
 7ba:	9e39                	addw	a2,a2,a4
 7bc:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7be:	ff053703          	ld	a4,-16(a0)
 7c2:	e398                	sd	a4,0(a5)
 7c4:	a099                	j	80a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c6:	6398                	ld	a4,0(a5)
 7c8:	00e7e463          	bltu	a5,a4,7d0 <free+0x40>
 7cc:	00e6ea63          	bltu	a3,a4,7e0 <free+0x50>
{
 7d0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7d2:	fed7fae3          	bgeu	a5,a3,7c6 <free+0x36>
 7d6:	6398                	ld	a4,0(a5)
 7d8:	00e6e463          	bltu	a3,a4,7e0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7dc:	fee7eae3          	bltu	a5,a4,7d0 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7e0:	ff852583          	lw	a1,-8(a0)
 7e4:	6390                	ld	a2,0(a5)
 7e6:	02059713          	slli	a4,a1,0x20
 7ea:	9301                	srli	a4,a4,0x20
 7ec:	0712                	slli	a4,a4,0x4
 7ee:	9736                	add	a4,a4,a3
 7f0:	fae60ae3          	beq	a2,a4,7a4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7f4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7f8:	4790                	lw	a2,8(a5)
 7fa:	02061713          	slli	a4,a2,0x20
 7fe:	9301                	srli	a4,a4,0x20
 800:	0712                	slli	a4,a4,0x4
 802:	973e                	add	a4,a4,a5
 804:	fae689e3          	beq	a3,a4,7b6 <free+0x26>
  } else
    p->s.ptr = bp;
 808:	e394                	sd	a3,0(a5)
  freep = p;
 80a:	00000717          	auipc	a4,0x0
 80e:	14f73f23          	sd	a5,350(a4) # 968 <freep>
}
 812:	6422                	ld	s0,8(sp)
 814:	0141                	addi	sp,sp,16
 816:	8082                	ret

0000000000000818 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 818:	7139                	addi	sp,sp,-64
 81a:	fc06                	sd	ra,56(sp)
 81c:	f822                	sd	s0,48(sp)
 81e:	f426                	sd	s1,40(sp)
 820:	f04a                	sd	s2,32(sp)
 822:	ec4e                	sd	s3,24(sp)
 824:	e852                	sd	s4,16(sp)
 826:	e456                	sd	s5,8(sp)
 828:	e05a                	sd	s6,0(sp)
 82a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 82c:	02051493          	slli	s1,a0,0x20
 830:	9081                	srli	s1,s1,0x20
 832:	04bd                	addi	s1,s1,15
 834:	8091                	srli	s1,s1,0x4
 836:	0014899b          	addiw	s3,s1,1
 83a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 83c:	00000517          	auipc	a0,0x0
 840:	12c53503          	ld	a0,300(a0) # 968 <freep>
 844:	c515                	beqz	a0,870 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 846:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 848:	4798                	lw	a4,8(a5)
 84a:	02977f63          	bgeu	a4,s1,888 <malloc+0x70>
 84e:	8a4e                	mv	s4,s3
 850:	0009871b          	sext.w	a4,s3
 854:	6685                	lui	a3,0x1
 856:	00d77363          	bgeu	a4,a3,85c <malloc+0x44>
 85a:	6a05                	lui	s4,0x1
 85c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 860:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 864:	00000917          	auipc	s2,0x0
 868:	10490913          	addi	s2,s2,260 # 968 <freep>
  if(p == (char*)-1)
 86c:	5afd                	li	s5,-1
 86e:	a88d                	j	8e0 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 870:	00000797          	auipc	a5,0x0
 874:	10078793          	addi	a5,a5,256 # 970 <base>
 878:	00000717          	auipc	a4,0x0
 87c:	0ef73823          	sd	a5,240(a4) # 968 <freep>
 880:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 882:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 886:	b7e1                	j	84e <malloc+0x36>
      if(p->s.size == nunits)
 888:	02e48b63          	beq	s1,a4,8be <malloc+0xa6>
        p->s.size -= nunits;
 88c:	4137073b          	subw	a4,a4,s3
 890:	c798                	sw	a4,8(a5)
        p += p->s.size;
 892:	1702                	slli	a4,a4,0x20
 894:	9301                	srli	a4,a4,0x20
 896:	0712                	slli	a4,a4,0x4
 898:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 89a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 89e:	00000717          	auipc	a4,0x0
 8a2:	0ca73523          	sd	a0,202(a4) # 968 <freep>
      return (void*)(p + 1);
 8a6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8aa:	70e2                	ld	ra,56(sp)
 8ac:	7442                	ld	s0,48(sp)
 8ae:	74a2                	ld	s1,40(sp)
 8b0:	7902                	ld	s2,32(sp)
 8b2:	69e2                	ld	s3,24(sp)
 8b4:	6a42                	ld	s4,16(sp)
 8b6:	6aa2                	ld	s5,8(sp)
 8b8:	6b02                	ld	s6,0(sp)
 8ba:	6121                	addi	sp,sp,64
 8bc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8be:	6398                	ld	a4,0(a5)
 8c0:	e118                	sd	a4,0(a0)
 8c2:	bff1                	j	89e <malloc+0x86>
  hp->s.size = nu;
 8c4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8c8:	0541                	addi	a0,a0,16
 8ca:	00000097          	auipc	ra,0x0
 8ce:	ec6080e7          	jalr	-314(ra) # 790 <free>
  return freep;
 8d2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8d6:	d971                	beqz	a0,8aa <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8d8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8da:	4798                	lw	a4,8(a5)
 8dc:	fa9776e3          	bgeu	a4,s1,888 <malloc+0x70>
    if(p == freep)
 8e0:	00093703          	ld	a4,0(s2)
 8e4:	853e                	mv	a0,a5
 8e6:	fef719e3          	bne	a4,a5,8d8 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8ea:	8552                	mv	a0,s4
 8ec:	00000097          	auipc	ra,0x0
 8f0:	b66080e7          	jalr	-1178(ra) # 452 <sbrk>
  if(p == (char*)-1)
 8f4:	fd5518e3          	bne	a0,s5,8c4 <malloc+0xac>
        return 0;
 8f8:	4501                	li	a0,0
 8fa:	bf45                	j	8aa <malloc+0x92>
