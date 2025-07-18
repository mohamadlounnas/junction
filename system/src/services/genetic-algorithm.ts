/**
 * Genetic Algorithm Enhancement for Algeria Real Estate AI
 * 
 * Implements sophisticated genetic optimization for recommendation vectors
 * Designed for real-world investor deployment with extensive validation
 */

import { PrismaClient } from '@prisma/client';
import { calculateSimilarity } from './score-generator';

const prisma = new PrismaClient();

// Genetic Algorithm Configuration
export const GA_CONFIG = {
  POPULATION_SIZE: 20,          // Number of vector variants per user
  MUTATION_RATE: 0.15,          // 15% chance of mutation per gene
  MUTATION_STRENGTH: 0.05,      // Maximum mutation magnitude
  CROSSOVER_RATE: 0.8,          // 80% chance of crossover
  ELITE_SIZE: 4,                // Top performers to preserve
  GENERATIONS: 50,              // Evolution cycles
  CONVERGENCE_THRESHOLD: 0.001, // Stop if improvement < 0.1%
  FITNESS_MEMORY: 10,           // Remember last N fitness scores
  DIVERSITY_THRESHOLD: 0.1      // Minimum population diversity
} as const;

interface GeneticIndividual {
  id: string;
  vector: number[];           // 12D preference vector
  fitness: number;           // Performance score
  age: number;               // Generations survived
  parentIds?: string[];      // For tracking lineage
  mutationHistory: string[]; // Mutation log
}

interface GeneticPopulation {
  contactId: string;
  individuals: GeneticIndividual[];
  generation: number;
  bestFitness: number;
  averageFitness: number;
  diversity: number;
  convergenceHistory: number[];
}

interface GeneticTestResult {
  contactId: string;
  contactName: string;
  originalAccuracy: number;
  geneticAccuracy: number;
  improvement: number;
  generations: number;
  finalDiversity: number;
  bestIndividual: GeneticIndividual;
  convergencePattern: number[];
}

/**
 * Generate initial population for a contact
 */
export function generateInitialPopulation(
  contactId: string, 
  baseVector: number[]
): GeneticPopulation {
  const individuals: GeneticIndividual[] = [];
  
  // Add the original vector as elite
  individuals.push({
    id: `${contactId}_original`,
    vector: [...baseVector],
    fitness: 0,
    age: 0,
    mutationHistory: ['original']
  });
  
  // Generate diverse variants
  for (let i = 1; i < GA_CONFIG.POPULATION_SIZE; i++) {
    const variant = [...baseVector];
    
    // Apply controlled mutations to create diversity
    for (let j = 0; j < variant.length; j++) {
      if (Math.random() < GA_CONFIG.MUTATION_RATE * 2) { // Higher initial mutation
        const mutation = (Math.random() - 0.5) * GA_CONFIG.MUTATION_STRENGTH * 2;
        variant[j] = Math.max(0, Math.min(1, variant[j] + mutation));
      }
    }
    
    individuals.push({
      id: `${contactId}_variant_${i}`,
      vector: variant,
      fitness: 0,
      age: 0,
      mutationHistory: ['initial_variant']
    });
  }
  
  return {
    contactId,
    individuals,
    generation: 0,
    bestFitness: 0,
    averageFitness: 0,
    diversity: 1,
    convergenceHistory: []
  };
}

/**
 * Calculate fitness score for an individual
 */
export async function calculateFitness(
  individual: GeneticIndividual,
  contactId: string
): Promise<number> {
  // Get contact's actual preferences and recent sales
  const contact = await prisma.contact.findUnique({
    where: { id: contactId },
    include: {
      sales: {
        orderBy: { saleDate: 'desc' },
        take: 10,
        include: { property: true }
      }
    }
  });
  
  if (!contact || contact.sales.length === 0) {
    // No sales history - use property similarity as proxy
    return await calculatePropertyMatchFitness(individual, contact!);
  }
  
  let totalFitness = 0;
  let validSales = 0;
  
  // Calculate fitness based on how well this vector would have predicted actual sales
  for (const sale of contact.sales) {
    const similarity = calculateSimilarity(individual.vector, sale.property.scores);
    
    // Weight by success score - successful sales should have high similarity
    const expectedSimilarity = sale.successScore;
    const predictionAccuracy = 1 - Math.abs(similarity - expectedSimilarity);
    
    // Factor in decision time - faster decisions indicate stronger preferences
    const timeWeight = sale.timeToDecision ? 
      Math.max(0.5, 1 - (sale.timeToDecision / 90)) : 0.8;
    
    totalFitness += predictionAccuracy * timeWeight * sale.successScore;
    validSales++;
  }
  
  if (validSales === 0) return 0;
  
  // Normalize fitness
  const baseFitness = totalFitness / validSales;
  
  // Bonus for vector stability (penalize extreme values)
  const stabilityBonus = calculateVectorStability(individual.vector);
  
  return Math.max(0, Math.min(1, baseFitness + stabilityBonus * 0.1));
}

/**
 * Alternative fitness calculation for contacts without sales history
 */
async function calculatePropertyMatchFitness(
  individual: GeneticIndividual,
  contact: any
): Promise<number> {
  const availableProperties = await prisma.property.findMany({
    where: {
      status: 'AVAILABLE',
      transactionType: contact.transactionType
    },
    take: 50 // Sample for performance
  });
  
  if (availableProperties.length === 0) return 0;
  
  // Calculate how well this vector matches available properties
  const similarities = availableProperties.map(property => 
    calculateSimilarity(individual.vector, property.scores)
  );
  
  // Fitness based on having good matches but not being too generic
  const avgSimilarity = similarities.reduce((sum, sim) => sum + sim, 0) / similarities.length;
  const maxSimilarity = Math.max(...similarities);
  const diversity = 1 - (similarities.filter(sim => sim > 0.8).length / similarities.length);
  
  return (avgSimilarity * 0.4 + maxSimilarity * 0.4 + diversity * 0.2);
}

/**
 * Calculate vector stability bonus
 */
function calculateVectorStability(vector: number[]): number {
  const extremes = vector.filter(v => v < 0.1 || v > 0.9).length;
  const variance = calculateVariance(vector);
  return Math.max(0, 1 - (extremes / vector.length) - variance);
}

/**
 * Calculate variance of vector values
 */
function calculateVariance(values: number[]): number {
  const mean = values.reduce((sum, val) => sum + val, 0) / values.length;
  const squaredDiffs = values.map(val => Math.pow(val - mean, 2));
  return squaredDiffs.reduce((sum, diff) => sum + diff, 0) / values.length;
}

/**
 * Calculate population diversity
 */
export function calculateDiversity(population: GeneticPopulation): number {
  const individuals = population.individuals;
  let totalDistance = 0;
  let comparisons = 0;
  
  for (let i = 0; i < individuals.length; i++) {
    for (let j = i + 1; j < individuals.length; j++) {
      const distance = euclideanDistance(individuals[i].vector, individuals[j].vector);
      totalDistance += distance;
      comparisons++;
    }
  }
  
  return comparisons > 0 ? totalDistance / comparisons : 0;
}

/**
 * Euclidean distance between two vectors
 */
function euclideanDistance(vec1: number[], vec2: number[]): number {
  const sum = vec1.reduce((acc, val, i) => acc + Math.pow(val - vec2[i], 2), 0);
  return Math.sqrt(sum);
}

/**
 * Selection using tournament selection
 */
export function tournamentSelection(
  population: GeneticPopulation, 
  tournamentSize: number = 3
): GeneticIndividual {
  const tournament: GeneticIndividual[] = [];
  
  for (let i = 0; i < tournamentSize; i++) {
    const randomIndex = Math.floor(Math.random() * population.individuals.length);
    tournament.push(population.individuals[randomIndex]);
  }
  
  return tournament.reduce((best, current) => 
    current.fitness > best.fitness ? current : best
  );
}

/**
 * Crossover operation - blend successful vectors
 */
export function crossover(
  parent1: GeneticIndividual, 
  parent2: GeneticIndividual,
  generation: number
): GeneticIndividual {
  const child: GeneticIndividual = {
    id: `gen${generation}_cross_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    vector: new Array(parent1.vector.length),
    fitness: 0,
    age: 0,
    parentIds: [parent1.id, parent2.id],
    mutationHistory: ['crossover']
  };
  
  // Blend vectors with bias toward fitter parent
  const fitnessDiff = Math.abs(parent1.fitness - parent2.fitness);
  const blendRatio = fitnessDiff > 0.1 ? 0.7 : 0.5; // Favor much fitter parent
  
  for (let i = 0; i < child.vector.length; i++) {
    if (parent1.fitness > parent2.fitness) {
      child.vector[i] = parent1.vector[i] * blendRatio + parent2.vector[i] * (1 - blendRatio);
    } else {
      child.vector[i] = parent2.vector[i] * blendRatio + parent1.vector[i] * (1 - blendRatio);
    }
    
    // Ensure bounds
    child.vector[i] = Math.max(0, Math.min(1, child.vector[i]));
  }
  
  return child;
}

/**
 * Mutation operation - small random changes
 */
export function mutate(
  individual: GeneticIndividual, 
  mutationRate: number = GA_CONFIG.MUTATION_RATE,
  mutationStrength: number = GA_CONFIG.MUTATION_STRENGTH
): GeneticIndividual {
  const mutated: GeneticIndividual = {
    ...individual,
    id: `${individual.id}_mut_${Date.now()}`,
    vector: [...individual.vector],
    mutationHistory: [...individual.mutationHistory]
  };
  
  let mutationsApplied = 0;
  
  for (let i = 0; i < mutated.vector.length; i++) {
    if (Math.random() < mutationRate) {
      const mutation = (Math.random() - 0.5) * mutationStrength * 2;
      mutated.vector[i] = Math.max(0, Math.min(1, mutated.vector[i] + mutation));
      mutationsApplied++;
    }
  }
  
  if (mutationsApplied > 0) {
    mutated.mutationHistory.push(`mut_${mutationsApplied}_genes`);
  }
  
  return mutated;
}

/**
 * Evolve population for one generation
 */
export async function evolveGeneration(population: GeneticPopulation): Promise<GeneticPopulation> {
  // Calculate fitness for all individuals
  for (const individual of population.individuals) {
    individual.fitness = await calculateFitness(individual, population.contactId);
  }
  
  // Sort by fitness
  population.individuals.sort((a, b) => b.fitness - a.fitness);
  
  // Calculate population statistics
  const bestFitness = population.individuals[0].fitness;
  const averageFitness = population.individuals.reduce((sum, ind) => sum + ind.fitness, 0) / population.individuals.length;
  const diversity = calculateDiversity(population);
  
  // Elite preservation
  const newGeneration: GeneticIndividual[] = [];
  const elites = population.individuals.slice(0, GA_CONFIG.ELITE_SIZE);
  elites.forEach(elite => {
    elite.age++;
    newGeneration.push(elite);
  });
  
  // Generate offspring
  while (newGeneration.length < GA_CONFIG.POPULATION_SIZE) {
    const parent1 = tournamentSelection(population);
    const parent2 = tournamentSelection(population);
    
    let offspring: GeneticIndividual;
    
    if (Math.random() < GA_CONFIG.CROSSOVER_RATE) {
      offspring = crossover(parent1, parent2, population.generation + 1);
    } else {
      offspring = { ...parent1, id: `gen${population.generation + 1}_${Date.now()}` };
    }
    
    // Apply mutation
    if (Math.random() < GA_CONFIG.MUTATION_RATE || diversity < GA_CONFIG.DIVERSITY_THRESHOLD) {
      offspring = mutate(offspring);
    }
    
    newGeneration.push(offspring);
  }
  
  return {
    ...population,
    individuals: newGeneration,
    generation: population.generation + 1,
    bestFitness,
    averageFitness,
    diversity,
    convergenceHistory: [...population.convergenceHistory, bestFitness]
  };
}

/**
 * Run full genetic algorithm optimization
 */
export async function runGeneticOptimization(
  contactId: string,
  baseVector: number[]
): Promise<GeneticTestResult> {
  console.log(`🧬 Starting genetic optimization for contact ${contactId}...`);
  
  const contact = await prisma.contact.findUnique({ where: { id: contactId } });
  if (!contact) throw new Error(`Contact ${contactId} not found`);
  
  // Initialize population
  let population = generateInitialPopulation(contactId, baseVector);
  
  // Calculate original accuracy
  const originalAccuracy = await calculateFitness({
    id: 'original',
    vector: baseVector,
    fitness: 0,
    age: 0,
    mutationHistory: []
  }, contactId);
  
  let bestOverallFitness = 0;
  let bestIndividual: GeneticIndividual | null = null;
  let generationsWithoutImprovement = 0;
  
  // Evolution loop
  for (let gen = 0; gen < GA_CONFIG.GENERATIONS; gen++) {
    population = await evolveGeneration(population);
    
    const currentBest = population.individuals[0];
    
    if (currentBest.fitness > bestOverallFitness) {
      bestOverallFitness = currentBest.fitness;
      bestIndividual = { ...currentBest };
      generationsWithoutImprovement = 0;
    } else {
      generationsWithoutImprovement++;
    }
    
    // Early stopping if converged
    if (generationsWithoutImprovement > 10 && 
        population.convergenceHistory.length > 5) {
      const recentImprovement = population.convergenceHistory.slice(-5);
      const improvement = Math.max(...recentImprovement) - Math.min(...recentImprovement);
      
      if (improvement < GA_CONFIG.CONVERGENCE_THRESHOLD) {
        console.log(`   🎯 Converged at generation ${gen + 1}`);
        break;
      }
    }
    
    if ((gen + 1) % 10 === 0) {
      console.log(`   Gen ${gen + 1}: Best=${currentBest.fitness.toFixed(3)}, ` +
                 `Avg=${population.averageFitness.toFixed(3)}, ` +
                 `Diversity=${population.diversity.toFixed(3)}`);
    }
  }
  
  if (!bestIndividual) {
    bestIndividual = population.individuals[0];
  }
  
  const improvement = ((bestOverallFitness - originalAccuracy) / originalAccuracy) * 100;
  
  return {
    contactId,
    contactName: contact.name,
    originalAccuracy,
    geneticAccuracy: bestOverallFitness,
    improvement,
    generations: population.generation,
    finalDiversity: population.diversity,
    bestIndividual,
    convergencePattern: population.convergenceHistory
  };
}

/**
 * Apply genetic optimization to a contact's preference vector
 */
export async function applyGeneticOptimization(contactId: string): Promise<GeneticTestResult> {
  const contact = await prisma.contact.findUnique({ where: { id: contactId } });
  if (!contact) throw new Error(`Contact ${contactId} not found`);
  
  const result = await runGeneticOptimization(contactId, contact.scores);
  
  // Update contact with optimized vector if improvement is significant
  if (result.improvement > 5) { // 5% improvement threshold
    await prisma.contact.update({
      where: { id: contactId },
      data: { 
        scores: result.bestIndividual.vector,
        // Add metadata about genetic optimization
        notes: `${contact.notes || ''}\n[GA Optimized: +${result.improvement.toFixed(1)}% improvement after ${result.generations} generations]`
      }
    });
    
    console.log(`✅ Applied genetic optimization to ${contact.name}: +${result.improvement.toFixed(1)}% improvement`);
  }
  
  return result;
} 