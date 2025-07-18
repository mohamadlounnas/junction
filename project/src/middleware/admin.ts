import { Elysia } from 'elysia';
import { PrismaClient, UserType } from '../../generated/prisma';

const prisma = new PrismaClient();

/**
 * Admin Middleware - Laravel-style admin authentication
 * Checks if user has admin privileges (AGENT role)
 */
export const adminMiddleware = new Elysia()
  .derive(async ({ request }) => {
    try {
      // Get authorization header
      const authHeader = request.headers.get('Authorization');
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Unauthorized: Missing or invalid authorization header');
      }

      const token = authHeader.substring(7); // Remove 'Bearer ' prefix
      
      // For now, we'll use a simple approach: token is the user ID
      // In production, you'd want to implement proper JWT tokens
      const user = await prisma.user.findUnique({
        where: { id: token },
        select: {
          id: true,
          email: true,
          name: true,
          userType: true
        }
      });

      if (!user) {
        throw new Error('Unauthorized: Invalid user token');
      }

      // Check if user is admin (AGENT role)
      if (user.userType !== UserType.AGENT) {
        throw new Error('Forbidden: Admin access required');
      }

      return {
        admin: user
      };
    } catch (error) {
      throw new Error(`Admin authentication failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  })
  .onError(({ code, error, set }) => {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    if (code === 'VALIDATION' || errorMessage.includes('Unauthorized') || errorMessage.includes('Forbidden')) {
      set.status = 401;
      return {
        success: false,
        error: 'Authentication failed',
        message: errorMessage
      };
    }
    
    set.status = 500;
    return {
      success: false,
      error: 'Internal server error',
      message: errorMessage
    };
  }); 