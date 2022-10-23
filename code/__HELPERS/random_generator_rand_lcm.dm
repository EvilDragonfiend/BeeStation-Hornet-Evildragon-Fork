#define PRIME_NUMBER_10TH_TO_20TH list(29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71)
#define SAFE_RAND_MAX 121000000
// I caluclated most situations using this random value system, and 11000 is the most safe value due to Byond magic.
// otherwise, it can cause some override issue or something like that. I can hard tell how it is though.

/proc/rand_EPG(my_rand_seed, maximum=6, flat_base = 1, number_of_return=0)
	/* rand_EPG [Evildragon's Pseudo random value Generator]
	< Purpose >
		rand() proc doesn't return a fixated value when we want to have.
		It can possible to return a fixated value, as long as we set a rand seed of the proc
		but rand() is used by a lot of codes, so giving a new rand seed isn't a good idea.

		This proc returns a fixated random value - it's Pseudo randome value generator.
		If you put the same value seed into this proc(with the same parameters), it will return the same result.
		But the result will be different for each round, because of [repeat] and [multiplier] value.

	< How to use >
		[my_rand_seed]
			literally seed. just don't put weird value.

		[maximum]
			if 6, random range becomes 0~5 (=6 possibilities)
			if 100, random range becomes 0~99 (=100 possibilities)

		[flat_base] (case 0~5)
			if 1, adds 1 to 0~5 (becomes 1~6)
			if 0, adds 0 to 0~5
			if 10, adds 10 to 0~5 (becomes 10~15)
			if -10, adds -10 to 0~5 (becomes -10~5)

		[number_of_return=0]
			if 0: returns `number`
			if 1: returns `list(one number)`
			if 2 (ore more than it): returns `list(number, number, ...)

		if you need 0~100 calculation, (maximum=101, flat_base=0) is correct
		if you want this feature as prob, use `prob_LCM()` below.

	< Error Code List >
		EPG00: [my_rand_seed] must be positive value.
		EPG01: [maximum] must be positive value.
		EPG02: If you're trying to calculate a number more than 121,000,000
				DreamMaker can possibly be broken because it can't calculate it properly due to the engine issue.
				It seems overflow issue. Do not try to make such big number.
		EPG03: [chance] must be number. It can accept minus chance.
	*/
	var/static/repeat = rand(20,40)
	var/static/divider = pick(PRIME_NUMBER_10TH_TO_20TH)
	// these will make the given random seed unpredictable

	if(!my_rand_seed || !isnum(my_rand_seed))
		CRASH("rand seed is not positive value: [my_rand_seed]. ErrorCode: EPG00")
	if(my_rand_seed > SAFE_RAND_MAX)
		stack_trace("rand seed is beyond the safe value: [my_rand_seed]. ErrorCode: EPG02")
	if(!maximum)
		CRASH("maximum value is not positive value: [maximum]. ErrorCode: EPG01")
	if(maximum > SAFE_RAND_MAX)
		stack_trace("maximum value is beyond the safe value: [my_rand_seed]. ErrorCode: EPG02")

	if(number_of_return)
		. = list()
	number_of_return = 1

	for(var/repeat in 1 to repeat)
		var/calc = my_rand_seed % divider
		for(var/i in 1 to repeat)
			calc *= divider
			calc %= maximum
		if(calc > SAFE_RAND_MAX)
			stack_trace("rand result value is beyond the safe value: [calc]. ErrorCode: EPG02")
		. += calc + flat_base

	return .

/proc/prob_LCM(chance, my_rand_seed)
	/* How to use:
		if(prob_LCM(55, my_seed)) // 55% chance to success/45% to fail by given seed
			print("SUCCESS!")

		the return value
	*/
	if(!isnum(chance))
		CRASH("chance value must be number: [chance]. ErrorCode: EPG03")
	if(!my_rand_seed || !isnum(my_rand_seed))
		CRASH("rand seed is not positive value: [my_rand_seed]. ErrorCode: EPG00")
	if(my_rand_seed > SAFE_RAND_MAX)
		stack_trace("rand seed is beyond the safe value: [my_rand_seed]. ErrorCode: EPG02")
	. = rand_EPG(my_rand_seed, maximum=10001, flat_base=0)/100
	world.log << "LCM chance: [chance]"
	world.log << "LCM result: [.]"
	world.log << "RESULT: [. < 100-chance]"
	return . < chance ? . : FALSE

