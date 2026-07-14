CC = mpicc
CFLAGS = -Wall -O3
INCLUDES = -I./include
LDFLAGS = -lm

SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj
BIN_DIR = .

SOURCES = $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
TARGET = summa

all: directories $(TARGET)

directories:
	mkdir -p $(OBJ_DIR)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(INC_DIR)/*.h
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf $(OBJ_DIR) $(TARGET)

run:
	mpirun -np 16 ./summa -m 4096 -n 4096 -k 4096 -b 128 -s c -v -p

valgrind_all:
	# Valgrind tests for all test cases with output appended into individual files 
	@for np in 4 16 64; do \	
		# Square matrix (4096x4096) for Stationary-A \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		echo "Testing with $$np processes for Stationary-A" >> valgrind_all_a64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Memcheck: Square Matrix (4096 x 4096) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 4096 -n 4096 -k 4096 -b 128 -s a -p >> valgrind_$$np_a_square4096x4096.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Massif: Square Matrix (4096 x 4096) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 4096 -n 4096 -k 4096 -b 128 -s a -p >> massif_$$np_a_square4096x4096.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Callgrind: Square Matrix (4096 x 4096) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_a_square4096x4096_output.txt ./summa -m 4096 -n 4096 -k 4096 -b 128 -s a -p >> callgrind_$$np_a_square4096x4096.txt 2>&1; \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		\
		# Rectangular matrix (4096x128) for Stationary-A \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		echo "Testing with $$np processes for Stationary-A" >> valgrind_all_a64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Memcheck: Rectangular Matrix (4096 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 4096 -n 4096 -k 128 -b 128 -s a -p >> valgrind_$$np_a_rect4096x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Massif: Rectangular Matrix (4096 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 4096 -n 4096 -k 128 -b 128 -s a -p >> massif_$$np_a_rect4096x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Callgrind: Rectangular Matrix (4096 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_a_rect4096x128_output.txt ./summa -m 4096 -n 4096 -k 128 -b 128 -s a -p >> callgrind_$$np_a_rect4096x128.txt 2>&1; \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		\
		# Rectangular matrix (8192x128) for Stationary-A \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		echo "Testing with $$np processes for Stationary-A" >> valgrind_all_a64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Memcheck: Rectangular Matrix (8192 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 8192 -n 8192 -k 128 -b 128 -s a -p >> valgrind_$$np_a_rect8192x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Massif: Rectangular Matrix (8192 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 8192 -n 8192 -k 128 -b 128 -s a -p >> massif_$$np_a_rect8192x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Callgrind: Rectangular Matrix (8192 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_a_rect8192x128_output.txt ./summa -m 8192 -n 8192 -k 128 -b 128 -s a -p >> callgrind_$$np_a_rect8192x128.txt 2>&1; \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		\
		# Rectangular matrix (16384x128) for Stationary-A \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		echo "Testing with $$np processes for Stationary-A" >> valgrind_all_a64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Memcheck: Rectangular Matrix (16384 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 16384 -n 16384 -k 128 -b 128 -s a -p >> valgrind_$$np_a_rect16384x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Massif: Rectangular Matrix (16384 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 16384 -n 16384 -k 128 -b 128 -s a -p >> massif_$$np_a_rect16384x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_a64_output.txt; \
		echo "Valgrind Callgrind: Rectangular Matrix (16384 x 128) with $$np processes (Stationary-A)" >> valgrind_all_a64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_a_rect16384x128_output.txt ./summa -m 16384 -n 16384 -k 128 -b 128 -s a -p >> callgrind_$$np_a_rect16384x128.txt 2>&1; \
		echo "===============================================" >> valgrind_all_a64_output.txt; \
		\
		# Square matrix (4096x4096) for Stationary-C \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
		echo "Testing with $$np processes for Stationary-C" >> valgrind_all_c64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Memcheck: Square Matrix (4096 x 4096) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 4096 -n 4096 -k 4096 -b 128 -s c -p >> valgrind_$$np_c_square4096x4096.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Massif: Square Matrix (4096 x 4096) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 4096 -n 4096 -k 4096 -b 128 -s c -p >> massif_$$np_c_square4096x4096.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Callgrind: Square Matrix (4096 x 4096) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_c_square4096x4096_output.txt ./summa -m 4096 -n 4096 -k 4096 -b 128 -s c -p >> callgrind_$$np_c_square4096x4096.txt 2>&1; \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
		\
		# Rectangular matrix (4096x128) for Stationary-C \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
		echo "Testing with $$np processes for Stationary-C" >> valgrind_all_c64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Memcheck: Rectangular Matrix (4096 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 4096 -n 4096 -k 128 -b 128 -s c -p >> valgrind_$$np_c_rect4096x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Massif: Rectangular Matrix (4096 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 4096 -n 4096 -k 128 -b 128 -s c -p >> massif_$$np_c_rect4096x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Callgrind: Rectangular Matrix (4096 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_c_rect4096x128_output.txt ./summa -m 4096 -n 4096 -k 128 -b 128 -s c -p >> callgrind_$$np_c_rect4096x128.txt 2>&1; \
		echo "===============================================" >> valgrind_all_c64_output.txt;
		\
		# Rectangular matrix (8192x128) for Stationary-C \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
		echo "Testing with $$np processes for Stationary-C" >> valgrind_all_c64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Memcheck: Rectangular Matrix (8192 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 8192 -n 8192 -k 128 -b 128 -s c -p >> valgrind_$$np_c_rect8192x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Massif: Rectangular Matrix (8192 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 8192 -n 8192 -k 128 -b 128 -s c -p >> massif_$$np_c_rect8192x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Callgrind: Rectangular Matrix (8192 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_c_rect8192x128_output.txt ./summa -m 8192 -n 8192 -k 128 -b 128 -s c -p >> callgrind_$$np_c_rect8192x128.txt 2>&1; \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
		\
		# Rectangular matrix (16384x128) for Stationary-C \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
		echo "Testing with $$np processes for Stationary-C" >> valgrind_all_c64_output.txt; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Memcheck: Rectangular Matrix (16384 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose ./summa -m 16384 -n 16384 -k 128 -b 128 -s c -p >> valgrind_$$np_c_rect16384x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Massif: Rectangular Matrix (16384 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=massif --massif-out-file=massif_$$np.out ./summa -m 16384 -n 16384 -k 128 -b 128 -s c -p >> massif_$$np_c_rect16384x128.txt 2>&1; \
		echo "-----------------------------------------------" >> valgrind_all_c64_output.txt; \
		echo "Valgrind Callgrind: Rectangular Matrix (16384 x 128) with $$np processes (Stationary-C)" >> valgrind_all_c64_output.txt; \
		mpirun -np $$np valgrind --tool=callgrind --callgrind-out-file=callgrind_$$np_c_rect16384x128_output.txt ./summa -m 16384 -n 16384 -k 128 -b 128 -s c -p >> callgrind_$$np_c_rect16384x128.txt 2>&1; \
		echo "===============================================" >> valgrind_all_c64_output.txt; \
	done

.PHONY: all clean run directories valgrind_all




